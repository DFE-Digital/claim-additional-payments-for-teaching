class ClaimsController < BasePublicController
  before_action :set_cache_headers
  before_action :check_whether_closed_for_submissions, if: :current_journey_routing_name
  before_action :create_session_if_skip_landing_page, if: :skip_landing_page?
  before_action :send_unstarted_claimants_to_the_start, if: :send_to_start?

  helper_method :submitted_claim

  def create_session_if_skip_landing_page
    journey_session || create_journey_session!
  end

  before_action :check_page_is_authorised, only: [:show]
  before_action :check_page_is_permissible, only: [:show]
  before_action :set_backlink_path, only: [:show, :update]
  before_action :check_claim_not_in_progress, only: [:new]
  before_action :clear_claim_session, only: [:new], unless: -> { journey.start_with_magic_link? }
  before_action :prepend_view_path_for_journey
  before_action :persist_claim, only: [:new, :create]
  before_action :handle_magic_link, only: [:new], if: -> { journey.start_with_magic_link? }
  before_action :add_answers_to_rollbar_context, only: [:show, :update]

  # ordering of these includes is important
  # moving them elsewhere will likely cause issues
  include FormSubmittable

  def existing_session
    @existing_session = journey_sessions.first
  end

  def start_new
    return redirect_to existing_session_path, alert: t("session.errors.select_continue_or_start_a_new_eligibility_check") unless params[:start_new_claim].present?

    if ActiveModel::Type::Boolean.new.cast(params[:start_new_claim]) == true
      clear_claim_session
      redirect_to(new_claim_path(current_journey_routing_name))
    else
      redirect_to_existing_claim_journey
    end
  end

  def signed_out
  end

  private

  def slug_sequence
    @slug_sequence ||= journey::SlugSequence.new(journey_session)
  end

  def navigator
    @navigator ||= Journeys::Navigator.new(
      current_slug: params[:slug],
      slug_sequence: slug_sequence,
      params:,
      session:
    )
  end
  helper_method :navigator

  def current_slug
    params[:slug]
  end

  def next_slug
    navigator.next_slug
  end

  def previous_slug
    navigator.previous_slug
  end

  def redirect_to_existing_claim_journey
    # If other journey sessions is empty, then the claimant has hit the landing
    # page for the journey they're already on, so we need to look at the
    # existing session.
    other_journey_session = other_journey_sessions.first || journey_session
    new_journey = Journeys.for_routing_name(other_journey_session.journey)

    temp_navigator = Journeys::Navigator.new(
      current_slug: nil,
      slug_sequence: new_journey::SlugSequence.new(other_journey_session),
      params:,
      session:
    )

    redirect_to(claim_path(new_journey::ROUTING_NAME, slug: temp_navigator.furthest_permissible_slug)) && return
  end

  def set_backlink_path
    return if navigator.current_slug == "confirmation"

    if previous_slug.present? && slug_sequence.class::DEAD_END_SLUGS.exclude?(current_slug)
      @backlink_path = claim_path(current_journey_routing_name, previous_slug)
    end
  end

  def persist_claim
    # Setting the journey name in the session is required for omniauth
    # callbacks congtroller, as we're redirected to a generic url so we can't
    # infer the journey from the params, and for refreshing the session as that
    # hits a non namespaced url. See
    # JourneyConcern#current_journey_routing_name and
    # OmniauthCallbacksController#current_journey_routing_name for where we use
    # this session value.
    session[:current_journey_routing_name] = current_journey_routing_name

    create_journey_session!
  end

  def check_page_is_authorised
    if navigator.requires_authorisation? && !navigator.authorised_slug?
      redirect_to claim_path(current_journey_routing_name, "unauthorised")
    end
  end

  def check_page_is_permissible
    unless navigator.permissible_slug?
      redirect_to claim_path(current_journey_routing_name, navigator.furthest_permissible_slug)
    end
  end

  def check_claim_not_in_progress
    redirect_to(existing_session_path(journey: current_journey_routing_name)) if eligible_claim_in_progress? && !journey.start_with_magic_link?
  end

  def prepend_view_path_for_journey
    prepend_view_path("app/views/#{current_journey_routing_name.underscore}")
  end

  def correct_journey_for_claim_in_progress?
    journey == Journeys.for_routing_name(journey_session.journey) if journey_session
  end

  def handle_magic_link
    return unless params[:code] && params[:email]

    otp = OneTimePassword::Validator.new(params[:code], secret: ROTP::Base32.encode(ENV.fetch("EY_MAGIC_LINK_SECRET") + params[:email]))

    if otp.valid?
      journey_session.answers.assign_attributes(
        provider_email_address: params[:email],
        invalid_magic_link: false
      )
    else
      journey_session.answers.assign_attributes(
        invalid_magic_link: true
      )
    end

    journey_session.save!

    redirect_to claim_path(current_journey_routing_name, navigator.furthest_permissible_slug)
  end

  def add_answers_to_rollbar_context
    return unless journey_session

    Rollbar.scope!(answers: journey_session.answers.attributes_with_pii_redacted)

    Sentry.configure_scope do |scope|
      scope.set_context(
        "Journey session anwers",
        journey_session.answers.attributes_with_pii_redacted
      )
    end
  end

  def check_whether_closed_for_submissions
    return if session[:submitted_claim_id].present?

    unless journey.accessible?(access_code)
      @availability_message = journey_configuration.availability_message
      render "static_pages/closed_for_submissions", status: :service_unavailable
    end
  end

  def access_code
    if journey_session
      journey_session.answers.service_access_code
    else
      # We've been redirected from the landing page and this callback
      # is running before the new action, so we're yet to create the
      # journey session.
      params.fetch(:answers, {})[:service_access_code]
    end
  end

  def send_unstarted_claimants_to_the_start
    redirect_to journey.start_page_url, allow_other_host: true
  end

  def skip_landing_page?
    params[:skip_landing_page] == "true"
  end

  def send_to_start?
    return false if %w[new create signed_out].include?(action_name)
    return false if navigator.current_slug == "confirmation"

    !skip_landing_page? && journey_sessions.none?
  end

  def submitted_claim
    return unless session[:submitted_claim_id]

    Claim.by_policies_for_journey(journey).find_by(id: session[:submitted_claim_id])
  end

  def set_cache_headers
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end
end
