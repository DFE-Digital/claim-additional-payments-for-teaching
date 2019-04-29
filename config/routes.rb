Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get "start/index"
  root "claims#new"

  resource :claim, only: [:new, :create] do
    member do
      get :qts_year
    end
  end
end
