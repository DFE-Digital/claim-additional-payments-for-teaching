Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: redirect(Rails.application.config.guidance_url)

  get "/claim/auth/tid/callback", to: "omniauth_callbacks#callback"
  get "/auth/failure", to: "omniauth_callbacks#failure"
  get "/auth/onelogin", to: "omniauth_callbacks#onelogin"
  if OneLoginSignIn.bypass?
    post "/auth/onelogin", to: "omniauth_callbacks#onelogin"
    post "/auth/onelogin_identity", to: "omniauth_callbacks#onelogin"
  end

  delete "deauth/onelogin", to: "deauth#onelogin"
  get "deauth/onelogin/callback", to: "deauth#onelogin_callback"

  # /early-career-payments is now /additional-payments - redirect old urls to a gov page
  get "early-career-payments(/*anything)", to: redirect("https://www.gov.uk/government/collections/additional-payments-for-teaching-eligibility-and-payment-details")

  # setup a simple healthcheck endpoint for monitoring purposes
  get "/healthcheck", to: proc { [200, {}, ["OK"]] }

  # Used to constrain claim journey routing so only slugs
  # that are part of a journey's slug sequence are routed.
  restrict_to_sequence_slugs = Class.new {
    attr_reader :journey

    def initialize(journey)
      @journey = journey
    end

    def matches?(request)
      request.path_parameters[:journey] == journey::ROUTING_NAME && journey.slug_sequence::SLUGS.include?(request.path_parameters[:slug])
    end
  }

  # Define routes that are specific to each journey's page sequence
  Journeys.all.each do |journey|
    constraints(restrict_to_sequence_slugs.new(journey)) do
      scope path: ":journey" do
        resources :claims, only: [:show, :update], param: :slug, path: "/"
      end
    end
  end

  # Define the generic routes that aren't specific to any given journey
  scope path: ":journey", constraints: {journey: %r{#{Journeys.all_routing_names.join("|")}}} do
    get "claim", as: :new_claim, to: "claims#new"
    post "claim", as: :claims, to: "claims#create"
    post "claim/submit", as: :claim_submission, to: "submissions#create"
    get "claims/confirmation", as: :claim_confirmation, to: "submissions#show"
    get "existing-session", as: :existing_session, to: "claims#existing_session"
    post "start-new", to: "claims#start_new", as: :start_new

    %w[terms_conditions contact_us accessibility_statement].each do |page_name|
      get page_name.dasherize, to: "static_pages##{page_name}", as: page_name
    end

    get "cookies", to: "static_pages#cookies_page"

    resource :cookies, only: [:update] do
      collection do
        post "accept"
        post "reject"
        post "hide"
      end
    end

    resources :unsubscribe,
      path: "/unsubscribe/:resource_class",
      constraints: {resource_class: /reminders/},
      only: [:create, :show]

    scope constraints: {journey: /further-education-payments|additional-payments/} do
      resources :reminders,
        only: [:show, :update],
        param: :slug,
        controller: "reminders",
        constraints: {
          slug: %r{#{Journeys::Reminders::SlugSequence::SLUGS.join("|")}}
        }
    end

    scope constraints: {journey: /early-years-payment/} do
      get "guidance", to: "journeys/early_years_payment/provider/start/static_pages#guidance", as: :guidance
      get "consent-form", to: "journeys/early_years_payment/provider/start/static_pages#consent_form"
    end

    scope constraints: {journey: "further-education-payments-provider"} do
      get "auth/callback", to: "omniauth_callbacks#callback"
      get "auth/sign-out", to: "omniauth_callbacks#sign_out"
    end

    scope path: "/", constraints: {journey: Regexp.new(Journeys.all_routing_names.join("|"))} do
      get "landing-page", to: "static_pages#landing_page", as: :landing_page
    end
  end

  constraints lambda { |req| req.format == :json } do
    defaults format: :json do
      resources :school_search, only: [:create]
    end
  end

  namespace :admin do
    get "/", to: "page#index", as: :root

    get "/auth/sign-in" => "auth#sign_in", :as => :sign_in
    delete "/auth/sign-out" => "auth#sign_out", :as => :sign_out

    # DfE Sign-in OpenID routes
    get "/auth/callback", to: "auth#callback"
    get "/auth/failure", to: "auth#failure"

    if DfESignIn.bypass?
      post "/auth/developer/callback", to: "auth#bypass_callback", as: :dfe_sign_in_bypass_callback
    end

    resources :claims, only: [:index, :show] do
      resources :tasks, only: [:index, :show, :create, :update], param: :name, constraints: {name: %r{#{Task::NAMES.join("|")}}}
      resources :payroll_gender_tasks, only: [:create], param: :name, name: "payroll_gender"
      resources :decisions, only: [:create, :new, :index] do
        resources :undos, only: [:create, :new], controller: "decisions_undo"
      end
      resources :amendments, only: [:index, :new, :create]
      resources :notes, only: [:index, :create]
      resources :support_tickets, only: [:create]
      resources :topups, only: [:new, :create, :destroy] do
        get :remove, on: :member
      end
      resources :payments, only: [:index]
      get "search", on: :collection
      patch "hold"
      patch "unhold"
      namespace :further_education_payments do
        resources :provider_verification_emails, only: [:create]
      end
    end

    resources :qualification_report_uploads, only: [:new, :create]
    resources :school_workforce_census_data_uploads, only: [:new, :create]
    resources :student_loans_data_uploads, only: [:new, :create]
    resources :tps_data_uploads, only: [:new, :create]
    resources :fraud_risk_csv_uploads, only: [:new, :create]
    resource :fraud_risk_csv_download, only: :show

    resources :payroll_runs, only: [:index, :new, :create, :show, :destroy] do
      resources :payment_confirmation_report_uploads, only: [:new, :create]
      resource :download, only: [:new, :create, :show], controller: "payroll_run_downloads"
      resources :payments, only: [:destroy] do
        get :remove, on: :member
      end
    end

    resources :payments, only: :show

    resources :journey_configurations, only: [:index, :edit, :update]
    resources :targeted_retention_incentive_payments_awards, only: [:index, :create]
    resource :eligible_ey_providers, only: [:create, :show], path: "eligible-early-years-providers"
    resource :eligible_fe_providers, only: [:create, :show], path: "eligible-further-education-providers"
    resources :reports, only: [:index, :show]

    get "refresh-session", to: "sessions#refresh", as: :refresh_session

    patch "allocate/:id", to: "allocations#allocate", as: :allocate
    delete "allocate/:id", to: "allocations#deallocate", as: :deallocate
    patch "bulk_allocate", to: "allocations#bulk_allocate"
    patch "bulk_deallocate", to: "allocations#bulk_deallocate"

    get "accessibility-statement", to: "static_pages#accessibility_statement"
    get "cookies", to: "static_pages#cookies_page"

    resource :cookies, only: [:update] do
      collection do
        post "accept"
        post "reject"
        post "hide"
      end
    end
  end

  # We still want to know about 404s in case of missing a route, but silence a whitelist instead to reduce the noise in Rollbar
  # This is not exhastive, so add more if there are obvious requests to ignore

  # 404 - extensions we don't expect
  match "*path", to: "application#handle_unwanted_requests", via: :all, constraints: lambda { |req|
    req.path =~ %r{\.(axd|asp|aspx|cgi|htm|html|php|php7|pl|txt|xml)$}i
  }

  # 404 - folders
  match "*path", to: "application#handle_unwanted_requests", via: :all, constraints: lambda { |req|
    req.path =~ %r{^/\.git/config$}i ||
      req.path =~ %r{^/cgi-bin}i ||
      req.path =~ %r{^/webui}i
  }

  # 404 - hard-coded apple icons - gov uk seems to 404 these as well
  match "*path", to: "application#handle_unwanted_requests", via: :all, constraints: lambda { |req|
    req.path =~ %r{^/apple-touch-icon(-120x120)?(-precomposed)?\.png$}i
  }

  # 404 - wordpress
  match "*path", to: "application#handle_unwanted_requests", via: :all, constraints: lambda { |req|
    req.path =~ %r{^/(wordpress|wp)}i
  }

  # 400 - any head requests
  match "*path", to: "application#handle_unwanted_requests", via: :head

  # 404 - root requests
  options "/", to: "application#handle_unwanted_requests"
end
