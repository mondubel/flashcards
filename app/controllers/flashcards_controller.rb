class FlashcardsController < ApplicationController
    before_action :authenticate_user!

    def index
        @flashcards = current_user.flashcards
    end

    def show
        @flashcard = current_user.flashcards.find(params[:id])
    end

    def create
        @flashcard = current_user.flashcards.create(flashcard_params)
    end

    def update
        @flashcard = current_user.flashcards.find(params[:id])
        @flashcard.update(flashcard_params)
    end

    def destroy
        @flashcard = current_user.flashcards.find(params[:id])
        @flashcard.destroy
    end

    private
    
    def flashcard_params
        params.require(:flashcard).permit(:front, :back, :source, :generation_id)
    end
end
