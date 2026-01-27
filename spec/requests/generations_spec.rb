require 'rails_helper'

RSpec.describe "Generations", type: :request do
  let(:user) { create(:user) }
  let(:valid_source_text) { 'A' * 1500 } # Minimum 1000 characters

  before do
    sign_in user
  end

  describe "GET /generations" do
    it "returns http success" do
      get generations_path
      expect(response).to have_http_status(:success)
    end

    it "displays user's generations" do
      generation1 = create(:generation, user: user, source_text: valid_source_text)
      generation2 = create(:generation, user: user, source_text: valid_source_text)

      get generations_path

      expect(response.body).to include(generation1.id.to_s)
      expect(response.body).to include(generation2.id.to_s)
    end

    it "does not display other users' generations" do
      other_user = create(:user)
      other_generation = create(:generation, user: other_user, source_text: valid_source_text)

      get generations_path

      expect(response.body).not_to include(other_generation.id.to_s)
    end
  end

  describe "GET /generations/:id" do
    let(:generation) { create(:generation, user: user, source_text: valid_source_text) }

    it "returns http success" do
      get generation_path(generation)
      expect(response).to have_http_status(:success)
    end

    it "displays generation details" do
      get generation_path(generation)
      expect(response.body).to include(generation.source_text[0..50])
    end

    context "when generation belongs to another user" do
      let(:other_user) { create(:user) }
      let(:other_generation) { create(:generation, user: other_user, source_text: valid_source_text) }

      it "renders 404 page when trying to access another user's generation" do
        get generation_path(other_generation)
        expect(response).to have_http_status(:not_found)
        expect(response.body).to include('Not Found')
      end
    end
  end

  describe "GET /generations/new" do
    it "returns http success" do
      get new_generation_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /generations" do
    let(:source_text) { 'Rails is a web framework. ' * 100 } # ~2700 chars

    context "when generation is successful" do
      before do
        # Mock FlashcardGenerationService with new response format
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
      end

      it "creates a new generation" do
        expect {
          post generations_path, params: { generation: { source_text: source_text } }
        }.to change(Generation, :count).by(1)
      end

      it "stores generated flashcards data" do
        post generations_path, params: { generation: { source_text: source_text } }

        generation = Generation.last
        expect(generation.generated_flashcards).to be_an(Array)
        expect(generation.generated_flashcards.length).to eq(2)
      end

      it "stores generation metadata" do
        post generations_path, params: { generation: { source_text: source_text } }

        generation = Generation.last
        expect(generation.model).to eq('openai/gpt-4o-mini')
        expect(generation.generation_duration).to eq(1500)
        expect(generation.generated_count).to eq(2)
      end

      it "redirects to review page" do
        post generations_path, params: { generation: { source_text: source_text } }

        generation = Generation.last
        expect(response).to redirect_to(review_generation_path(generation))
      end

      it "does not create flashcards immediately" do
        expect {
          post generations_path, params: { generation: { source_text: source_text } }
        }.not_to change(Flashcard, :count)
      end
    end

    context "when source text is too short" do
      it "does not create generation" do
        expect {
          post generations_path, params: { generation: { source_text: 'Too short' } }
        }.not_to change(Generation, :count)
      end

      it "renders new template with errors" do
        post generations_path, params: { generation: { source_text: 'Too short' } }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('errors')
      end
    end

    context "when source text is too long" do
      let(:long_text) { 'A' * 10_001 }

      it "does not create generation" do
        expect {
          post generations_path, params: { generation: { source_text: long_text } }
        }.not_to change(Generation, :count)
      end

      it "renders new template with errors" do
        post generations_path, params: { generation: { source_text: long_text } }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when OpenRouter returns rate limit error" do
      before do
        allow_any_instance_of(FlashcardGenerationService).to receive(:generate)
          .and_raise(OpenRouterService::RateLimitError, 'Rate limit exceeded')
      end

      it "does not create generation" do
        expect {
          post generations_path, params: { generation: { source_text: source_text } }
        }.not_to change(Generation, :count)
      end

      it "renders new template with rate limit message" do
        post generations_path, params: { generation: { source_text: source_text } }

        expect(response).to have_http_status(:too_many_requests)
        expect(response.body).to include('Too many requests')
      end
    end

    context "when OpenRouter returns insufficient credits error" do
      before do
        allow_any_instance_of(FlashcardGenerationService).to receive(:generate)
          .and_raise(OpenRouterService::InsufficientCreditsError, 'Insufficient credits')
      end

      it "renders new template with service unavailable message" do
        post generations_path, params: { generation: { source_text: source_text } }

        expect(response).to have_http_status(:service_unavailable)
        expect(response.body).to include('Service temporarily unavailable')
      end
    end

    context "when OpenRouter returns network error" do
      before do
        allow_any_instance_of(FlashcardGenerationService).to receive(:generate)
          .and_raise(OpenRouterService::NetworkError, 'Network timeout')
      end

      it "renders new template with timeout message" do
        post generations_path, params: { generation: { source_text: source_text } }

        expect(response).to have_http_status(:request_timeout)
        expect(response.body).to include('Connection timeout')
      end
    end

    context "when OpenRouter returns authentication error" do
      before do
        allow_any_instance_of(FlashcardGenerationService).to receive(:generate)
          .and_raise(OpenRouterService::AuthenticationError, 'Invalid API key')
      end

      it "renders new template with configuration error message" do
        post generations_path, params: { generation: { source_text: source_text } }

        expect(response).to have_http_status(:service_unavailable)
        expect(response.body).to include('Service configuration error')
      end

      it "logs error message" do
        expect(Rails.logger).to receive(:error).with(/authentication failed/)

        post generations_path, params: { generation: { source_text: source_text } }
      end
    end

    context "when OpenRouter returns general API error" do
      before do
        allow_any_instance_of(FlashcardGenerationService).to receive(:generate)
          .and_raise(OpenRouterService::APIError, 'API error')
      end

      it "renders new template with generic error message" do
        post generations_path, params: { generation: { source_text: source_text } }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('Failed to generate flashcards')
      end

      it "logs error details" do
        expect(Rails.logger).to receive(:error).with(/API error/)
        expect(Rails.logger).to receive(:error).with(String) # backtrace

        post generations_path, params: { generation: { source_text: source_text } }
      end
    end

    context "when generation save fails" do
      before do
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
      end

      it "does not create generation" do
        expect {
          post generations_path, params: { generation: { source_text: source_text } }
        }.not_to change(Generation, :count)
      end

      it "renders new template with error" do
        post generations_path, params: { generation: { source_text: source_text } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  context "when user is not authenticated" do
    before do
      sign_out user
    end

    it "redirects to sign in page for index" do
      get generations_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects to sign in page for show" do
      generation = create(:generation, user: user, source_text: valid_source_text)
      get generation_path(generation)
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects to sign in page for new" do
      get new_generation_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects to sign in page for create" do
      post generations_path, params: { generation: { source_text: valid_source_text } }
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
