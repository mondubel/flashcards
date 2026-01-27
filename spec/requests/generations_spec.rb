require 'rails_helper'

RSpec.describe "Generations", type: :request do
  describe "GET /generations" do
    it "returns http success" do
      user = create(:user)
      sign_in user

      get generations_path
      expect(response).to have_http_status(:success)
    end

    it "displays user's generations" do
      user = create(:user)
      valid_source_text = 'A' * 1500
      sign_in user

      generation1 = create(:generation, user: user, source_text: valid_source_text)
      generation2 = create(:generation, user: user, source_text: valid_source_text)

      get generations_path

      expect(response.body).to include(generation1.id.to_s)
      expect(response.body).to include(generation2.id.to_s)
    end

    it "does not display other users' generations" do
      user = create(:user)
      valid_source_text = 'A' * 1500
      user_generation = create(:generation, user: user, source_text: 'User generation text: ' + valid_source_text)
      sign_in user

      other_user = create(:user)
      other_generation = create(:generation, user: other_user, source_text: 'Other generation text: ' + valid_source_text)

      get generations_path

      expect(response.body).to include('User generation text:')
      expect(response.body).not_to include('Other generation text:')
    end
  end

  describe "GET /generations/:id" do
    it "returns http success" do
      user = create(:user)
      valid_source_text = 'A' * 1500
      sign_in user

      generation = create(:generation, user: user, source_text: valid_source_text)

      get generation_path(generation)
      expect(response).to have_http_status(:success)
    end

    it "displays generation details" do
      user = create(:user)
      valid_source_text = 'A' * 1500
      sign_in user

      generation = create(:generation, user: user, source_text: valid_source_text)

      get generation_path(generation)
      expect(response.body).to include(generation.source_text[0..50])
    end

    context "when generation belongs to another user" do
      it "renders 404 page when trying to access another user's generation" do
        user = create(:user)
        valid_source_text = 'A' * 1500
        sign_in user

        other_user = create(:user)
        other_generation = create(:generation, user: other_user, source_text: valid_source_text)

        get generation_path(other_generation)
        expect(response).to have_http_status(:not_found)
        expect(response.body).to include('Not Found')
      end
    end
  end

  describe "GET /generations/new" do
    it "returns http success" do
      user = create(:user)
      sign_in user

      get new_generation_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /generations" do
    context "when generation is successful" do
      it "creates a new generation" do
        user = create(:user)
        source_text = 'Rails is a web framework. ' * 100
        sign_in user

        allow_any_instance_of(FlashcardGenerationService).to receive(:generate).and_return({
          flashcards: [
            { front: 'What is Rails?', back: 'A web framework' },
            { front: 'What language is Rails written in?', back: 'Ruby' }
          ],
          metadata: {
            model: 'openai/gpt-4o-mini',
            generation_duration: 1500,
            generated_count: 2
          }
        })

        expect {
          post generations_path, params: { generation: { source_text: source_text } }
        }.to change(Generation, :count).by(1)
      end

      it "stores generated flashcards data" do
        user = create(:user)
        source_text = 'Rails is a web framework. ' * 100
        sign_in user

        allow_any_instance_of(FlashcardGenerationService).to receive(:generate).and_return({
          flashcards: [
            { front: 'What is Rails?', back: 'A web framework' },
            { front: 'What language is Rails written in?', back: 'Ruby' }
          ],
          metadata: {
            model: 'openai/gpt-4o-mini',
            generation_duration: 1500,
            generated_count: 2
          }
        })

        post generations_path, params: { generation: { source_text: source_text } }

        generation = Generation.last
        expect(generation.generated_flashcards).to be_an(Array)
        expect(generation.generated_flashcards.length).to eq(2)
      end

      it "stores generation metadata" do
        user = create(:user)
        source_text = 'Rails is a web framework. ' * 100
        sign_in user

        allow_any_instance_of(FlashcardGenerationService).to receive(:generate).and_return({
          flashcards: [
            { front: 'What is Rails?', back: 'A web framework' },
            { front: 'What language is Rails written in?', back: 'Ruby' }
          ],
          metadata: {
            model: 'openai/gpt-4o-mini',
            generation_duration: 1500,
            generated_count: 2
          }
        })

        post generations_path, params: { generation: { source_text: source_text } }

        generation = Generation.last
        expect(generation.model).to eq('openai/gpt-4o-mini')
        expect(generation.generation_duration).to eq(1500)
        expect(generation.generated_count).to eq(2)
      end

      it "redirects to review page" do
        user = create(:user)
        source_text = 'Rails is a web framework. ' * 100
        sign_in user

        allow_any_instance_of(FlashcardGenerationService).to receive(:generate).and_return({
          flashcards: [
            { front: 'What is Rails?', back: 'A web framework' },
            { front: 'What language is Rails written in?', back: 'Ruby' }
          ],
          metadata: {
            model: 'openai/gpt-4o-mini',
            generation_duration: 1500,
            generated_count: 2
          }
        })

        post generations_path, params: { generation: { source_text: source_text } }

        generation = Generation.last
        expect(response).to redirect_to(review_generation_path(generation))
      end

      it "does not create flashcards immediately" do
        user = create(:user)
        source_text = 'Rails is a web framework. ' * 100
        sign_in user

        allow_any_instance_of(FlashcardGenerationService).to receive(:generate).and_return({
          flashcards: [
            { front: 'What is Rails?', back: 'A web framework' },
            { front: 'What language is Rails written in?', back: 'Ruby' }
          ],
          metadata: {
            model: 'openai/gpt-4o-mini',
            generation_duration: 1500,
            generated_count: 2
          }
        })

        expect {
          post generations_path, params: { generation: { source_text: source_text } }
        }.not_to change(Flashcard, :count)
      end
    end

    context "when source text is too short" do
      it "does not create generation" do
        user = create(:user)
        sign_in user

        expect {
          post generations_path, params: { generation: { source_text: 'Too short' } }
        }.not_to change(Generation, :count)
      end

      it "renders new template with errors" do
        user = create(:user)
        sign_in user

        post generations_path, params: { generation: { source_text: 'Too short' } }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('errors')
      end
    end

    context "when source text is too long" do
      it "does not create generation" do
        user = create(:user)
        long_text = 'A' * 10_001
        sign_in user

        expect {
          post generations_path, params: { generation: { source_text: long_text } }
        }.not_to change(Generation, :count)
      end

      it "renders new template with errors" do
        user = create(:user)
        long_text = 'A' * 10_001
        sign_in user

        post generations_path, params: { generation: { source_text: long_text } }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when OpenRouter returns rate limit error" do
      it "does not create generation" do
        user = create(:user)
        source_text = 'Rails is a web framework. ' * 100
        sign_in user

        allow_any_instance_of(FlashcardGenerationService).to receive(:generate)
          .and_raise(OpenRouterService::RateLimitError, 'Rate limit exceeded')

        expect {
          post generations_path, params: { generation: { source_text: source_text } }
        }.not_to change(Generation, :count)
      end

      it "renders new template with rate limit message" do
        user = create(:user)
        source_text = 'Rails is a web framework. ' * 100
        sign_in user

        allow_any_instance_of(FlashcardGenerationService).to receive(:generate)
          .and_raise(OpenRouterService::RateLimitError, 'Rate limit exceeded')

        post generations_path, params: { generation: { source_text: source_text } }

        expect(response).to have_http_status(:too_many_requests)
        expect(response.body).to include('Too many requests')
      end
    end

    context "when OpenRouter returns insufficient credits error" do
      it "renders new template with service unavailable message" do
        user = create(:user)
        source_text = 'Rails is a web framework. ' * 100
        sign_in user

        allow_any_instance_of(FlashcardGenerationService).to receive(:generate)
          .and_raise(OpenRouterService::InsufficientCreditsError, 'Insufficient credits')

        post generations_path, params: { generation: { source_text: source_text } }

        expect(response).to have_http_status(:service_unavailable)
        expect(response.body).to include('Service temporarily unavailable')
      end
    end

    context "when OpenRouter returns network error" do
      it "renders new template with timeout message" do
        user = create(:user)
        source_text = 'Rails is a web framework. ' * 100
        sign_in user

        allow_any_instance_of(FlashcardGenerationService).to receive(:generate)
          .and_raise(OpenRouterService::NetworkError, 'Network timeout')

        post generations_path, params: { generation: { source_text: source_text } }

        expect(response).to have_http_status(:request_timeout)
        expect(response.body).to include('Connection timeout')
      end
    end

    context "when OpenRouter returns authentication error" do
      it "renders new template with configuration error message" do
        user = create(:user)
        source_text = 'Rails is a web framework. ' * 100
        sign_in user

        allow_any_instance_of(FlashcardGenerationService).to receive(:generate)
          .and_raise(OpenRouterService::AuthenticationError, 'Invalid API key')

        post generations_path, params: { generation: { source_text: source_text } }

        expect(response).to have_http_status(:service_unavailable)
        expect(response.body).to include('Service configuration error')
      end

      it "logs error message" do
        user = create(:user)
        source_text = 'Rails is a web framework. ' * 100
        sign_in user

        allow_any_instance_of(FlashcardGenerationService).to receive(:generate)
          .and_raise(OpenRouterService::AuthenticationError, 'Invalid API key')

        expect(Rails.logger).to receive(:error).with(/authentication failed/)

        post generations_path, params: { generation: { source_text: source_text } }
      end
    end

    context "when OpenRouter returns general API error" do
      it "renders new template with generic error message" do
        user = create(:user)
        source_text = 'Rails is a web framework. ' * 100
        sign_in user

        allow_any_instance_of(FlashcardGenerationService).to receive(:generate)
          .and_raise(OpenRouterService::APIError, 'API error')

        post generations_path, params: { generation: { source_text: source_text } }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('Failed to generate flashcards')
      end

      it "logs error details" do
        user = create(:user)
        source_text = 'Rails is a web framework. ' * 100
        sign_in user

        allow_any_instance_of(FlashcardGenerationService).to receive(:generate)
          .and_raise(OpenRouterService::APIError, 'API error')

        expect(Rails.logger).to receive(:error).with(/API error/)
        expect(Rails.logger).to receive(:error).with(String) # backtrace

        post generations_path, params: { generation: { source_text: source_text } }
      end
    end

    context "when generation save fails" do
      it "does not create generation" do
        user = create(:user)
        source_text = 'Rails is a web framework. ' * 100
        sign_in user

        allow_any_instance_of(FlashcardGenerationService).to receive(:generate).and_return({
          flashcards: [
            { front: 'Q1', back: 'A1' }
          ],
          metadata: {
            model: 'openai/gpt-4o-mini',
            generation_duration: 1000,
            generated_count: 1
          }
        })

        # Force generation save to fail
        allow_any_instance_of(Generation).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(Generation.new))

        expect {
          post generations_path, params: { generation: { source_text: source_text } }
        }.not_to change(Generation, :count)
      end

      it "renders new template with error" do
        user = create(:user)
        source_text = 'Rails is a web framework. ' * 100
        sign_in user

        allow_any_instance_of(FlashcardGenerationService).to receive(:generate).and_return({
          flashcards: [
            { front: 'Q1', back: 'A1' }
          ],
          metadata: {
            model: 'openai/gpt-4o-mini',
            generation_duration: 1000,
            generated_count: 1
          }
        })

        # Force generation save to fail
        allow_any_instance_of(Generation).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(Generation.new))

        post generations_path, params: { generation: { source_text: source_text } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  context "when user is not authenticated" do
    it "redirects to sign in page for index" do
      get generations_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects to sign in page for show" do
      user = create(:user)
      valid_source_text = 'A' * 1500
      generation = create(:generation, user: user, source_text: valid_source_text)

      get generation_path(generation)
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects to sign in page for new" do
      get new_generation_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects to sign in page for create" do
      valid_source_text = 'A' * 1500
      post generations_path, params: { generation: { source_text: valid_source_text } }
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
