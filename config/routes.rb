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
      request["journey"] == journey::ROUTING_NAME && journey.slug_sequence::SLUGS.include?(request["slug"])
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

    %w[terms_conditions contact_us cookies accessibility_statement].each do |page_name|
      get page_name.dasherize, to: "static_pages##{page_name}", as: page_name
    end

    scope constraints: {journey: "additional-payments"} do
      get "reminder", as: :new_reminder, to: "journeys/additional_payments_for_teaching/reminders#new"
      post "reminders/:slug", constraints: {slug: %r{#{Journeys::AdditionalPaymentsForTeaching::SlugSequence::REMINDER_SLUGS.join("|")}}}, defaults: {slug: "personal-details"}, as: :reminders, to: "journeys/additional_payments_for_teaching/reminders#create"
      resources :reminders, only: [:show, :update], param: :slug, constraints: {slug: %r{#{Journeys::AdditionalPaymentsForTeaching::SlugSequence::REMINDER_SLUGS.join("|")}}}, controller: "journeys/additional_payments_for_teaching/reminders"
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
    post "/auth/developer/callback", to: "auth#bypass_callback", as: :dfe_sign_in_bypass_callback

    resources :claims, only: [:index, :show] do
      resources :tasks, only: [:index, :show, :create, :update], param: :name, constraints: {name: %r{#{Task::NAMES.join("|")}}}
      resources :payroll_gender_tasks, only: [:create], param: :name, name: "payroll_gender"
      resources :decisions, only: [:create, :new] do
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
    end

    resources :qualification_report_uploads, only: [:new, :create]
    resources :school_workforce_census_data_uploads, only: [:new, :create]
    resources :student_loans_data_uploads, only: [:new, :create]
    resources :tps_data_uploads, only: [:new, :create]

    resources :payroll_runs, only: [:index, :new, :create, :show] do
      resources :payment_confirmation_report_uploads, only: [:new, :create]
      resource :download, only: [:new, :create, :show], controller: "payroll_run_downloads"
      resources :payments, only: [:destroy] do
        get :remove, on: :member
      end
    end

    resources :journey_configurations, only: [:index, :edit, :update]
    resources :levelling_up_premium_payments_awards, only: [:index, :create]
    resource :eligible_ey_providers, only: [:create, :show], path: "eligible-early-years-providers"
    resource :eligible_fe_providers, only: [:create, :show], path: "eligible-further-education-providers"

    get "refresh-session", to: "sessions#refresh", as: :refresh_session

    patch "allocate/:id", to: "allocations#allocate", as: :allocate
    delete "allocate/:id", to: "allocations#deallocate", as: :deallocate
    patch "bulk_allocate", to: "allocations#bulk_allocate"
    patch "bulk_deallocate", to: "allocations#bulk_deallocate"

    get "accessibility-statement", to: "static_pages#accessibility_statement"
  end
end
