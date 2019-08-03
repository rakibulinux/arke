Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :robots
      resources :accounts
      resources :balances, only: :index
      resources :trades, only: :index
      resources :markets, only: :index
      resources :tickers, only: :index
      resources :exchanges, only: :index

      get 'users/me', to: 'users#me'
    end
  end
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
