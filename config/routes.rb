Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root "static_pages#start_page"

  # setup a simple healthcheck endpoint for monitoring purposes
  get "/healthcheck", to: proc { [200, {}, ["OK"]] }

  # setup static pages
  get "/privacy_notice", to: "static_pages#privacy_notice", as: :privacy_notice
  get "/terms_conditions", to: "static_pages#terms_conditions", as: :terms_conditions
  get "/contact_us", to: "static_pages#contact_us", as: :contact_us
  get "/cookies", to: "static_pages#cookies", as: :cookies
  get "/accessibility_statement", to: "static_pages#accessibility_statement", as: :accessibility_statement

  constraints slug: %r{#{PageSequence::SLUGS.join("|")}} do
    resources :claims, only: [:new, :create, :show, :update], param: :slug, path: "/claim"
  end

  get "/claim/timeout", to: "claims#timeout", as: :timeout_claim
  get "/claim/refresh-session", to: "claims#refresh_session"

  constraints lambda { |req| req.format == :json } do
    defaults format: :json do
      resources :school_search, only: [:create]
    end
  end

  namespace :verify do
    resource :authentications, only: [:new, :create] do
      member do
        get "failed"
        get "no_auth"
      end
    end

    if Rails.env.test?
      require "verify/fake_sso"
      mount Verify::FakeSso.new("/verify/authentications"), at: "/fake_sso"
    end
  end

  namespace :admin do
    get "/", to: "page#index"

    get "/auth/sign-in" => "auth#sign_in", :as => :sign_in
    delete "/auth/sign-out" => "auth#sign_out", :as => :sign_out

    # DfE Sign-in OpenID routes
    post "/auth/dfe", as: :dfe_sign_in
    get "/auth/callback", to: "auth#callback"
    get "/auth/failure", to: "auth#failure"

    resources :claims, only: [:index]
  end
end
