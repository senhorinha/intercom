Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  namespace 'api' do
    resources :merchants, only: [:show, :destroy] do
      resources :groups, only: [:index, :create] do
        resources :messages, only: [:index, :create]
      end
      resources :messages, only: [:index, :create, :show]
    end
  end
  get "/support/" => "support#index"
  get "/support/:page" => "support#show"
  root "support#root"
end
