class FlashcardsController < ApplicationController
    before_action :authenticate_user!

    def index
        @flashcards = current_user.flashcards.order(created_at: :desc).paginate(page: params[:page], per_page: 12)

        # User-specific stats
        @user_stats = {
            ai_acceptance_rate: current_user.ai_acceptance_rate,
            ai_flashcards_percentage: current_user.ai_flashcards_percentage,
            total_flashcards: current_user.flashcards.count
        }

        # System-wide stats
        @system_stats = {
            ai_acceptance_rate: User.system_ai_acceptance_rate,
            ai_flashcards_percentage: User.system_ai_flashcards_percentage,
            total_flashcards: User.system_total_flashcards,
            total_users: User.system_total_users
        }
    end

    def show
        @flashcard = current_user.flashcards.find(params[:id])
    end

    def new
        @flashcard = current_user.flashcards.new
    end

    def create
        @flashcard = current_user.flashcards.build(flashcard_params)
        @flashcard.source = :manual

        if @flashcard.save
            redirect_to flashcards_path, notice: "Flashcard created successfully."
        else
            flash.now[:alert] = "Failed to create flashcard. Please check the errors below."
            render :new, status: :unprocessable_entity
        end
    end

    def edit
        @flashcard = current_user.flashcards.find(params[:id])
    end

    def update
        @flashcard = current_user.flashcards.find(params[:id])

        # Check if flashcard content changed and it was AI-generated
        content_changed = (@flashcard.front != flashcard_params[:front] ||
                          @flashcard.back != flashcard_params[:back])

        # Change source to ai_edited if it was ai_full and content changed
        if content_changed && @flashcard.ai_full?
            updated_params = flashcard_params.merge(source: :ai_edited)
        else
            updated_params = flashcard_params
        end

        if @flashcard.update(updated_params)
            redirect_to flashcards_path, notice: "Flashcard updated successfully."
        else
            flash.now[:alert] = "Failed to update flashcard. Please check the errors below."
            render :edit, status: :unprocessable_entity
        end
    end

    def destroy
        @flashcard = current_user.flashcards.find(params[:id])
        @flashcard.destroy
        redirect_to flashcards_path, notice: "Flashcard deleted successfully."
    end

    private

    def flashcard_params
        params.require(:flashcard).permit(:front, :back)
    end
end
