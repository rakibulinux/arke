Rails.application.routes.draw do
  get '/admin', to: 'admin#index'

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

    namespace :v2 do
      namespace :private do
        resources :robots
        resources :accounts
      end

      namespace :public do
        get :exchanges, to: 'exchanges#index'

        namespace :markets do
          resources :kline, path: "/:market/k-line", only: [:index]
          resources :trades, path: "/:market/trades", only: [:index]
          resources :tickers, only: [:index]
        end
      end
    end
  end
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
