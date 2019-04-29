Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get "start/index"
  root "claims#new"

  resource :claim, only: [:new, :create, :update] do
    member do
      get :qts_year
      get :claim_school
    end
  end
end
