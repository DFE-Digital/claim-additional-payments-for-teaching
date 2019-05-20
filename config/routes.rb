Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root "claims#new"

  constraints slug: %r{#{TslrClaim::PAGE_SEQUENCE.join("|")}} do
    resources :claims, only: [:new, :create, :show, :update], param: :slug, path: "/claim"
  end
  get "/claim/ineligible", to: "claims#ineligible", as: :ineligible_claim
  get "/claim/timeout", to: "claims#timeout", as: :timeout_claim
end
