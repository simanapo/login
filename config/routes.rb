Rails.application.routes.draw do
  devise_for :users, controllers: { :omniauth_callbacks => "omniauth_callbacks" }
  # root 'pages#index'
  # get 'pages/show'
  # get 'pages/search'

  resources :pages, only: [:index, :show, :create, :update, :destroy] do
    collection do
      post :confirm
      post :csv_upload
      post :csv_load
      get :search
    end
    member do
      patch :sort
      patch :update_confirm
    end
  end
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
