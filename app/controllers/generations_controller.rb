class GenerationsController < ApplicationController
  before_action :authenticate_user!

  def index
    @generations = current_user.generations.order(created_at: :desc).paginate(page: params[:page], per_page: 10)
  end

  def show
    @generation = current_user.generations.find(params[:id])
  end

  def new
    @generation = Generation.new
  end

  def create
    @generation = current_user.generations.build(generation_params)

    unless @generation.valid?
      flash.now[:alert] = "Please check the errors below."
      return render :new, status: :unprocessable_entity
    end

    begin
      ActiveRecord::Base.transaction do
        result = generate_flashcards(@generation.source_text)
        flashcards_data = result[:flashcards]
        metadata = result[:metadata]

        # Save generation with generated flashcards data and metadata for review
        @generation.generated_flashcards = flashcards_data
        @generation.model = metadata[:model]
        @generation.generation_duration = metadata[:generation_duration]
        @generation.generated_count = metadata[:generated_count]
        @generation.save!

        redirect_to review_generation_path(@generation),
                    notice: "Generated #{flashcards_data.count} flashcards. Review and select which ones to save."
      end
    rescue ActiveRecord::RecordInvalid => e
      flash.now[:alert] = "Failed to save generation: #{e.message}"
      render :new, status: :unprocessable_entity
    rescue OpenRouterService::RateLimitError
      handle_rate_limit_error
    rescue OpenRouterService::InsufficientCreditsError
      handle_insufficient_credits_error
    rescue OpenRouterService::NetworkError
      handle_network_error
    rescue OpenRouterService::AuthenticationError
      handle_authentication_error
    rescue OpenRouterService::Error => e
      handle_api_error(e)
    end
  end

  def review
    @generation = current_user.generations.find(params[:id])

    # Check if already reviewed
    if @generation.reviewed?
      flash[:alert] = "This generation has already been reviewed. Flashcards cannot be edited after review."
      return redirect_to generation_path(@generation)
    end

    @flashcards_data = @generation.generated_flashcards

    # If no generated flashcards data, redirect to show page
    if @flashcards_data.empty?
      flash[:alert] = "No flashcard data available for review. This generation may have been created with an older version."
      redirect_to generation_path(@generation)
    end
  end

  def save_flashcards
    @generation = current_user.generations.find(params[:id])
    flashcards_params = params.fetch(:flashcards, {})

    if flashcards_params.empty?
      flash[:alert] = "No flashcards to save."
      return redirect_to review_generation_path(@generation)
    end

    begin
      saved_count = 0
      unedited_count = 0
      edited_count = 0
      original_flashcards = @generation.generated_flashcards || []

      ActiveRecord::Base.transaction do
        flashcards_params.each do |index, card_params|
          next unless card_params[:selected] == "1"

          # Determine if flashcard was edited
          original_card = original_flashcards[index.to_i]
          was_edited = false

          if original_card
            original_front = original_card[:front] || original_card["front"]
            original_back = original_card[:back] || original_card["back"]
            was_edited = (card_params[:front] != original_front || card_params[:back] != original_back)
          end

          @generation.flashcards.create!(
            user: current_user,
            front: card_params[:front],
            back: card_params[:back],
            source: was_edited ? :ai_edited : :ai_full
          )

          if was_edited
            edited_count += 1
          else
            unedited_count += 1
          end
          saved_count += 1
        end

        # Update acceptance counts
        @generation.update!(
          reviewed: true,
          accepted_unedited_count: unedited_count,
          accepted_edited_count: edited_count
        )
      end

      if saved_count.zero?
        flash[:alert] = "No flashcards were selected. Please select at least one flashcard."
        redirect_to review_generation_path(@generation)
      else
        redirect_to generation_path(@generation),
                    notice: "Successfully saved #{saved_count} flashcard#{'s' unless saved_count == 1}."
      end
    rescue ActiveRecord::RecordInvalid => e
      flash.now[:alert] = "Error saving flashcards: #{e.message}"
      @flashcards_data = @generation.generated_flashcards || []
      render :review, status: :unprocessable_entity
    end
  end

  def save_all_flashcards
    @generation = current_user.generations.find(params[:id])
    flashcards_data = @generation.generated_flashcards || []

    begin
      saved_count = 0

      ActiveRecord::Base.transaction do
        flashcards_data.each do |card_data|
          @generation.flashcards.create!(
            user: current_user,
            front: card_data[:front] || card_data["front"],
            back: card_data[:back] || card_data["back"],
            source: :ai_full
          )
          saved_count += 1
        end

        # All flashcards are unedited when saving all
        @generation.update!(
          reviewed: true,
          accepted_unedited_count: saved_count,
          accepted_edited_count: 0
        )
      end

      redirect_to generation_path(@generation),
                  notice: "Successfully saved all #{saved_count} flashcards."
    rescue ActiveRecord::RecordInvalid => e
      flash[:alert] = "Error saving flashcards: #{e.message}"
      redirect_to review_generation_path(@generation)
    end
  end

  private

  def generate_flashcards(source_text)
    service = FlashcardGenerationService.new
    service.generate(source_text)
  end

  def handle_rate_limit_error
    flash.now[:alert] = "Too many requests. Please try again in a few minutes."
    render :new, status: :too_many_requests
  end

  def handle_insufficient_credits_error
    flash.now[:alert] = "Service temporarily unavailable. Please try again later."
    render :new, status: :service_unavailable
  end

  def handle_network_error
    flash.now[:alert] = "Connection timeout. Please check your internet connection and try again."
    render :new, status: :request_timeout
  end

  def handle_authentication_error
    Rails.logger.error("OpenRouter authentication failed. Check API key configuration.")
    flash.now[:alert] = "Service configuration error. Please contact support."
    render :new, status: :service_unavailable
  end

  def handle_api_error(error)
    Rails.logger.error("OpenRouter API error: #{error.class} - #{error.message}")
    Rails.logger.error(error.backtrace.join("\n"))

    flash.now[:alert] = "Failed to generate flashcards. Please try again or contact support if the problem persists."
    render :new, status: :unprocessable_entity
  end

  def generation_params
    params.require(:generation).permit(:source_text)
  end
end
