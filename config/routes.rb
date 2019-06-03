Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root "claims#new"

  constraints slug: %r{#{TslrClaim::PAGE_SEQUENCE.join("|")}} do
    resources :claims, only: [:new, :create, :show, :update], param: :slug, path: "/claim"
  end
  get "/claim/ineligible", to: "claims#ineligible", as: :ineligible_claim
  get "/claim/timeout", to: "claims#timeout", as: :timeout_claim
  get "/claim/refresh-session", to: "claims#refresh_session"

  namespace :admin do
    get "/", to: "page#index"

    get "/auth/sign-in" => "auth#sign_in", :as => :sign_in
    delete "/auth/sign-out" => "auth#sign_out", :as => :sign_out
    get "/auth/dfe", as: :dfe_sign_in
    get "/auth/callback", to: "auth#callback"
    get "/auth/failure", to: "auth#failure"
  end
end
