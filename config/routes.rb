Rails.application.routes.draw do
  # API routes
  namespace :api do
    devise_for :users, controllers: { 
      sessions: 'api/sessions',
      registrations: 'api/users'
    }, skip: [:registrations]  # Skip registrations if you're handling them separately for the API
    
    post 'refresh_token', to: 'sessions#refresh_token'
    
    resources :users, only: [:create, :show, :update]  # Add necessary user actions for API
    resources :workspaces, only: [:show, :create, :update, :destroy] do
      member do
        get 'search_by_phone_number'
        get 'get_data_for_room'
      end
    end
    resources :bookings
  end

  # Web routes (optional - for admin interface)
  devise_for :users

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
