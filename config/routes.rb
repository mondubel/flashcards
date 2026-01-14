Rails.application.routes.draw do
  devise_for :users
  root "flashcards#index"
  resources :flashcards
  resources :generations, only: [ :index, :show, :create, :new ]
end
