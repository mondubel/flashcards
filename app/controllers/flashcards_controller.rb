class FlashcardsController < ApplicationController
    before_action :authenticate_user!

    def index
        @flashcards = current_user.flashcards
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
            render :new, status: :unprocessable_entity
        end
    end

    def edit
        @flashcard = current_user.flashcards.find(params[:id])
    end

    def update
        @flashcard = current_user.flashcards.find(params[:id])
        
        if @flashcard.update(flashcard_params)
            redirect_to flashcards_path, notice: "Flashcard updated successfully."
        else
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
