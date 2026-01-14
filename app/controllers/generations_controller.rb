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
        @generation = current_user.generations.create(generation_params)
    end

    private

    def generation_params
        params.require(:generation).permit(:source_text)
    end
end
