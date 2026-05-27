Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations:  "users/registrations",
    sessions:       "users/sessions",
    confirmations:  "users/confirmations"
  }

  root "home#index"

  resource :guest_assessment, only: [ :new, :create ]

  resources :bulk_assessments, only: [ :new, :create, :show ] do
    member do
      get :progress
      post :retry_item
    end
  end

  resources :items do
    member do
      post :assess
      patch :update_action
    end
  end

  resources :todo_items do
    member do
      patch :toggle
    end
  end

  resources :memories do
    member do
      post :generate_ai_summary
      patch :toggle_share
    end
  end
  get "shared/:token", to: "memories#shared", as: :shared_memory

  resources :digital_items, only: [ :index, :create, :destroy ] do
    member do
      patch :toggle_status
    end
    collection do
      post :ai_generate
    end
  end

  resource :ai_consultation, only: [ :show ]
  resources :consultations, only: [ :create, :index ]

  resources :businesses do
    resources :inquiries, only: [ :create, :index, :update ]
    member do
      post :subscribe
      delete :unsubscribe
      get :dashboard
    end
    collection do
      get :search
      get :select_type
      get :email_sent
      get :pending
      get :for_estate_clearance
      get :for_resellers
    end
  end

  namespace :admin do
    root "dashboard#index"
    resources :users
    resources :businesses do
      member do
        post :approve
        post :reject
      end
    end
    resources :inquiries
    resources :settings, only: [ :index, :update ]
  end

  namespace :stripe do
    post :webhooks, to: "webhooks#create"
  end

  # /appraisals/:id → /items/:id へのリダイレクト（旧URLからのアクセス対応）
  get "/appraisals/:id", to: redirect("/items/%{id}")
  get "/appraisals", to: redirect("/items")

  get "up" => "rails/health#show", as: :rails_health_check
end
