# frozen_string_literal: true

Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  devise_for :users, skip: [:passwords] # TODO: :registrations if configured
  root 'sites#home'
  resources :batches, only: %i[index new create destroy] do
    namespace :step do
      %i[preprocesses processes transfers archives].each do |step|
        resources step, only: %i[new create show] do
          post 'cancel'
          post 'reset'
        end
      end
    end
  end
  resources :connections, except: %i[index show]
  get '/connections', to: redirect('/connections/new')
  get '/connections/:id', to: redirect('/connections/%{id}/edit')
  resources :groups, only: %i[index new create edit update destroy]
  get '/groups/:id', to: redirect('/groups/%{id}/edit')
  resources :manifests, only: %i[index destroy]
  resources :mappers, only: %i[index]
  get '/mappers/autocomplete', to: 'mappers#autocomplete'
  resources :users, except: %i[create new show] do
    post :impersonate, on: :member
    post :stop_impersonating, on: :collection
  end
  get '/users/:id', to: redirect('/users/%{id}/edit')
  get '/users/:id/group', to: redirect('/users/%{id}/edit')
  patch '/users/:id/group', to: 'users#update_group', as: 'user_group'

  authenticate :user, ->(u) { u.admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end
end
