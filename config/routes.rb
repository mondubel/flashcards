Rails.application.routes.draw do
  devise_for :users
  root "flashcards#index"
  resources :flashcards
  resources :generations, only: [ :index, :show, :create, :new ] do
    member do
      get :review
      post :save_flashcards
      post :save_all_flashcards
    end
  end
end
