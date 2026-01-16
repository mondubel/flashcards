class GenerationsController < ApplicationController
    before_action :authenticate_user!

    def index
        @generations = current_user.generations
    end

    def show
        @generation = current_user.generations.find(params[:id])
    end

    def new
        @generation = Generation.new
    end

    def create
        @generation = current_user.generations.build(generation_params)

        if @generation.save
            redirect_to generation_path(@generation), notice: "Generation created successfully."
        else
            flash.now[:alert] = "Failed to create generation. Please check the errors below."
            render :new, status: :unprocessable_entity
        end
    end

    private

    def generation_params
        params.require(:generation).permit(:source_text)
    end
end
