Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: redirect(Rails.application.config.guidance_url)

  # setup a simple healthcheck endpoint for monitoring purposes
  get "/healthcheck", to: proc { [200, {}, ["OK"]] }

  # If the CANONICAL_HOSTNAME env var is present, and the request doesn't come from that
  # hostname, redirect us to the canonical hostname with the path and query string present
  if ENV["CANONICAL_HOSTNAME"].present?
    constraints(host: Regexp.new("^(?!#{Regexp.escape(ENV["CANONICAL_HOSTNAME"])})")) do
      match "/(*path)" => redirect(host: ENV["CANONICAL_HOSTNAME"]), :via => [:all]
    end
  end

  get "refresh-session", to: "sessions#refresh", as: :refresh_session

  # Used to constrain claim journey routing so only slugs
  # that are part of a policy’s slug sequence are routed.
  restrict_to_sequence_slugs = Class.new {
    attr_reader :policy

    def initialize(policy)
      @policy = policy
    end

    def matches?(request)
      request["policy"] == policy.routing_name && policy::SlugSequence::SLUGS.include?(request["slug"])
    end
  }

  # Define routes that are specific to each Policy's page sequence
  Policies.all.each do |policy|
    constraints(restrict_to_sequence_slugs.new(policy)) do
      scope path: ":policy" do
        resources :claims, only: [:show, :update], param: :slug, path: "/"
      end
    end
  end
  # Define the generic routes that aren't specific to any given policy
  scope path: ":policy", constraints: {policy: %r{#{Policies.all.map(&:routing_name).join("|")}}} do
    get "claim", as: :new_claim, to: "claims#new"
    post "claim", as: :claims, to: "claims#create"
    post "claim/submit", as: :claim_submission, to: "submissions#create"
    get "claims/confirmation", as: :claim_confirmation, to: "submissions#show"
    get "timeout", to: "claims#timeout", as: :timeout_claim
    get "existing-session", as: :existing_session, to: "claims#existing_session"
    post "start-new", to: "claims#start_new", as: :start_new

    %w[privacy_notice terms_conditions contact_us cookies accessibility_statement].each do |page_name|
      get page_name.dasherize, to: "static_pages##{page_name}", as: page_name
    end

    scope path: "/", constraints: {policy: Policies.all.detect { |policy| policy.routing_name == "early-career-payments" }.routing_name} do
      get "landing-page", to: "static_pages#landing_page", as: :landing_page
    end
  end

  constraints lambda { |req| req.format == :json } do
    defaults format: :json do
      resources :school_search, only: [:create]
    end
  end

  # Redirect for Maths and Physics temporary start page
  get "maths-and-physics/start", to: redirect(MathsAndPhysics.start_page_url)

  namespace :admin do
    get "/", to: "page#index", as: :root

    get "/auth/sign-in" => "auth#sign_in", :as => :sign_in
    delete "/auth/sign-out" => "auth#sign_out", :as => :sign_out

    # DfE Sign-in OpenID routes
    post "/auth/dfe", as: :dfe_sign_in
    get "/auth/callback", to: "auth#callback"
    get "/auth/failure", to: "auth#failure"

    resources :claims, only: [:index, :show] do
      resources :tasks, only: [:index, :show, :create], param: :name, constraints: {name: %r{#{Task::NAMES.join("|")}}}
      resources :payroll_gender_tasks, only: [:create], param: :name, name: "payroll_gender"
      resources :decisions, only: [:create, :new] do
        resources :undos, only: [:create, :new], controller: "decisions_undo"
      end
      resources :amendments, only: [:index, :new, :create]
      resources :notes, only: [:index, :create]
      resources :support_tickets, only: [:create]
      get "search", on: :collection
    end

    resources :qualification_report_uploads, only: [:new, :create]

    resources :payroll_runs, only: [:index, :new, :create, :show] do
      resources :payment_confirmation_report_uploads, only: [:new, :create]
      resource :download, only: [:new, :create, :show], controller: "payroll_run_downloads"
      resources :payments, only: [:destroy] do
        get :remove, on: :member
      end
    end

    resources :policy_configurations, only: [:index, :edit, :update]
    get "refresh-session", to: "sessions#refresh", as: :refresh_session
  end
end
