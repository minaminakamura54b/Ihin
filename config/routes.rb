Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: "users/registrations",
    sessions: "users/sessions"
  }

  root "home#index"

  resource :guest_assessment, only: [:new, :create]

  resources :bulk_assessments, only: [:new, :create, :show] do
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

  resources :memories

  resource :ai_consultation, only: [:show]
  resources :consultations, only: [:create, :index]

  resources :businesses do
    resources :inquiries, only: [:create, :index, :update]
    member do
      post :subscribe
      delete :unsubscribe
      get :dashboard
    end
    collection do
      get :search
    end
  end

  namespace :admin do
    root "dashboard#index"
    resources :users
    resources :businesses
    resources :inquiries
    resources :settings, only: [:index, :update]
  end

  namespace :stripe do
    post :webhooks, to: "webhooks#create"
  end

  # /appraisals/:id → /items/:id へのリダイレクト（旧URLからのアクセス対応）
  get "/appraisals/:id", to: redirect("/items/%{id}")
  get "/appraisals", to: redirect("/items")

  get "up" => "rails/health#show", as: :rails_health_check
end
