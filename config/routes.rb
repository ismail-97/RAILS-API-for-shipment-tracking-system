Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :shipments do
        resources :contents
      end
      resources :customers
      resources :editors
      resources :travelers
      resources :orders
      resources :order_products
      resources :products
      resources :flights do
        resources :flight_expenses
      end

      post 'login', to: 'authentication#login'
    end
  end
end
