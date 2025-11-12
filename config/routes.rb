Rails.application.routes.draw do
  # Scoped Devise routes for Members (STI)
  devise_for :members, class_name: "Member", controllers: {
    registrations: "members/registrations",
    sessions: "members/sessions"
  }

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  namespace :account do
    resource :information, only: %i[show edit update]
    resources :subscriptions, only: %i[index update]
    resources :purchases, only: %i[index]
    resource :payment_method, only: %i[show update destroy]
  end

  resource :library, only: %i[show]
  resources :cart_items, only: %i[create update]
  resource :checkout, only: %i[show create]
  resources :newspapers, only: %i[show]
  resources :orders, only: %i[create] do
    member do
      get "verify"
      get "complete"
      get "receipt"
    end
  end

  namespace :admin do
    devise_for :users, class_name: "Admin::User", skip: [ :registrations ], controllers: {
      sessions: "admin/users/sessions",
      passwords: "admin/users/passwords"
    }

    resources :invitations, param: :token, only: [ :show ] do
      member do
        post :accept
      end
    end

    # Settings namespace with separate tabs
    namespace :settings do
      resource :team, only: [ :show, :update ] do
        delete "users/:id", to: "teams#destroy", as: :user
      end
      resource :company, only: [ :show, :update ]
      resource :pdf_source, only: [ :show, :update ]
      resources :pdf_imports, only: [ :create, :index ] do
        collection do
          get :status
        end
      end
    end

    # Note: Keep existing teams destroy route for backward compatibility with team deletion
    # This will be deprecated once all team management moves to settings

    # Redirect /admin/settings to default tab
    get "settings", to: redirect("/admin/settings/team")

    resources :customers, only: %i[index show edit update] do
      resources :subscriptions, only: %i[new create]
    end
    resources :subscriptions, only: %i[index show edit update]
    resource :overview, only: %i[show]
    resources :first_users do
      collection do
        get :set_email
      end
    end
    resources :products
    resources :members, only: [ :index, :edit, :update ]
    resources :newspapers

    resources :widgets, only: [] do
      collection do
        get :revenue
        get :active_subscriptions
        get :customers
        get :new_subscriptions
        get :revenue_chart
        get :customers_chart
      end
    end

    root "overviews#show"
  end

  # Style Guide (only accessible in development/staging)
  get "style-guide" => "style_guide#index", as: :style_guide

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "home#index"
end
