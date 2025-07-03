Rails.application.routes.draw do
  # API routes
  namespace :api do
    devise_for :users, controllers: { 
      sessions: 'api/sessions',
      registrations: 'api/users'
    }, skip: [:registrations]  # Skip registrations if you're handling them separately for the API
    
    devise_scope :user do
      post 'refresh_token', to: 'sessions#refresh_token'
    end
    
    get 'get_profile', to: 'user#get_profile'
    
    resources :users, only: [:create, :show, :update]  # Add necessary user actions for API
    resources :workspaces, only: [:show, :create, :update, :destroy] do
      member do
        get 'search_by_phone_number'
        get 'get_data_for_room'
      end
      resources :visitor_entries
      resources :bookings
      resources :office_enquiries
      resources :day_passes
      resources :rooms
    end
  end

  # Web routes (optional - for admin interface)
  devise_for :users, controllers: {
    sessions: 'custom_sessions'
  }

  # Admin routes
  namespace :admin do
    get '/', to: 'dashboard#index', as: :root
    get 'dashboard', to: 'dashboard#index'
    
    resources :workspaces do
      resources :rooms
      member do
        post :add_company
        delete :remove_company
      end
    end
    
    resources :rooms, only: [:index, :show]
    resources :bookings
    resources :companies do
      member do
        post :add_room
        delete :remove_room
        post :add_user
        delete :remove_user
        patch :quick_status_change
      end
    end
    
    resources :users do
      member do
        get :assign_workspace
        patch :assign_workspace
      end
    end
    
    resources :office_enquiries
    resources :visitor_entries
    resources :workspace_types
    
    resource :profile, only: [:show, :edit, :update], controller: 'profile'
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Bootstrap test route

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "admin/dashboard#index"
end
