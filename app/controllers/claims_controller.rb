class ClaimsController < BasePublicController
  include PartOfClaimJourney

  skip_before_action :send_unstarted_claimants_to_the_start, only: [:new, :create]
  before_action :initialize_session_slug_history
  before_action :check_page_is_in_sequence, only: [:show, :update]
  before_action :set_backlink_path, only: [:show, :update]
  before_action :check_claim_not_in_progress, only: [:new]
  before_action :clear_claim_session, only: [:new], unless: -> { journey.start_with_magic_link? }
  before_action :prepend_view_path_for_journey
  before_action :persist_claim, only: [:new, :create]
  before_action :handle_magic_link, only: [:new], if: -> { journey.start_with_magic_link? }
  before_action :add_answers_to_rollbar_context, only: [:show, :update]
  after_action :update_session_with_current_slug, only: [:update]

  include AuthorisedSlugs
  include FormSubmittable
  include ClaimsFormCallbacks
  include ClaimSubmission

  def existing_session
    @existing_session = journey_sessions.first
  end

  def start_new
    new_journey_description = translate("#{current_journey_routing_name.underscore}.claim_description")

    return redirect_to existing_session_path, alert: "Select yes if you want to start a claim #{new_journey_description}" unless params[:start_new_claim].present?

    if ActiveModel::Type::Boolean.new.cast(params[:start_new_claim]) == true
      clear_claim_session
      redirect_to(new_claim_path(current_journey_routing_name))
    else
      redirect_to_existing_claim_journey
    end
  end

  private

  delegate :slugs, :current_slug, :previous_slug, :next_slug, :next_required_slug, to: :page_sequence

  def redirect_to_existing_claim_journey
    # If other journey sessions is empty, then the claimant has hit the landing
    # page for the journey they're already on, so we need to look at the
    # existing session.
    other_journey_session = other_journey_sessions.first || journey_session
    new_journey = Journeys.for_routing_name(other_journey_session.journey)

    # Set the params[:journey] to the new journey routing name so things like
    # journey_session that rely on the journey param find the correct journey.
    params[:journey] = new_journey::ROUTING_NAME

    new_page_sequence = new_journey.page_sequence_for_claim(
      journey_session,
      session[:slugs],
      params[:slug]
    )
    redirect_to(claim_path(new_journey::ROUTING_NAME, slug: new_page_sequence.next_required_slug))
  end

  def set_backlink_path
    @backlink_path = claim_path(current_journey_routing_name, previous_slug) if previous_slug.present?
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

  def check_page_is_in_sequence
    unless correct_journey_for_claim_in_progress?
      clear_claim_session
      return redirect_to new_claim_path(request.query_parameters)
    end

    raise ActionController::RoutingError.new("Not Found for #{params[:slug]}") unless page_sequence.in_sequence?(params[:slug])

    redirect_to claim_path(current_journey_routing_name, next_required_slug) unless page_sequence.has_completed_journey_until?(params[:slug])
  end

  def initialize_session_slug_history
    session[:slugs] ||= []
  end

  def update_session_with_current_slug
    if @form.nil? || @form.valid?
      session[:slugs] << params[:slug] unless Journeys::PageSequence::DEAD_END_SLUGS.include?(params[:slug])
    else
      # Don't count form as visited if it's invalid
    end
  end

  def check_claim_not_in_progress
    redirect_to(existing_session_path(journey: current_journey_routing_name)) if eligible_claim_in_progress? && !journey.start_with_magic_link?
  end

  def page_sequence
    @page_sequence ||= journey.page_sequence_for_claim(
      journey_session,
      session[:slugs],
      params[:slug]
    )
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
      journey_session.answers.assign_attributes(provider_email_address: params[:email])
      journey_session.save!
    else
      redirect_to claim_path(Journeys::EarlyYearsPayment::Provider::Start::ROUTING_NAME, "expired-link") and return
    end
    redirect_to_next_slug if claim_in_progress?
  end

  def add_answers_to_rollbar_context
    return unless journey_session

    Rollbar.scope!(answers: journey_session.answers.attributes_with_pii_redacted)
  end
end
