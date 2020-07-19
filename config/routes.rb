# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users
  root 'sites#home'
  resources :users, except: %i[create new show] do
    post :impersonate, on: :member
    post :stop_impersonating, on: :collection
  end
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
