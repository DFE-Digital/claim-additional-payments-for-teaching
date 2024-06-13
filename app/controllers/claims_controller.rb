class ClaimsController < BasePublicController
  include PartOfClaimJourney

  skip_before_action :send_unstarted_claimants_to_the_start, only: [:new, :create, :timeout]
  before_action :initialize_session_slug_history
  before_action :check_page_is_in_sequence, only: [:show, :update]
  before_action :update_session_with_current_slug, only: [:update]
  before_action :set_backlink_path, only: [:show]
  before_action :check_claim_not_in_progress, only: [:new]
  before_action :clear_claim_session, only: [:new]
  before_action :prepend_view_path_for_journey
  before_action :persist_claim, only: [:new, :create]

  include FormSubmittable
  include ClaimsFormCallbacks

  def current_data_object
    current_claim
  end

  def timeout
  end

  def existing_session
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
    new_journey = Journeys.for_policy(current_claim.policy)

    # Set the params[:journey] to the new journey routing name so things like
    # journey_session that rely on the journey param find the correct journey.
    params[:journey] = new_journey::ROUTING_NAME

    new_page_sequence = new_journey.page_sequence_for_claim(
      current_claim,
      journey_session,
      session[:slugs],
      params[:slug]
    )
    redirect_to(claim_path(new_journey::ROUTING_NAME, slug: new_page_sequence.next_required_slug))
  end

  def set_backlink_path
    previous_slug = previous_slug()
    @backlink_path = claim_path(current_journey_routing_name, previous_slug) if previous_slug.present?
  end

  def persist_claim
    current_claim.save!
    session[:claim_id] = current_claim.claim_ids
    session[journey_session_key] = journey_session.id
  end

  def check_page_is_in_sequence
    unless correct_journey_for_claim_in_progress?
      clear_claim_session
      return redirect_to new_claim_path
    end

    raise ActionController::RoutingError.new("Not Found for #{params[:slug]}") unless page_sequence.in_sequence?(params[:slug])

    redirect_to claim_path(current_journey_routing_name, next_required_slug) unless page_sequence.has_completed_journey_until?(params[:slug])
  end

  def initialize_session_slug_history
    session[:slugs] ||= []
  end

  def update_session_with_current_slug
    session[:slugs] << params[:slug] unless Journeys::PageSequence::DEAD_END_SLUGS.include?(params[:slug])
  end

  def check_claim_not_in_progress
    redirect_to(existing_session_path(journey: current_journey_routing_name)) if claim_in_progress?
  end

  def claim_in_progress?
    session[:claim_id].present? && !claim_ineligible?
  end

  def claim_ineligible?
    journey::EligibilityChecker.new(journey_session: journey_session).ineligible?
  end

  def page_sequence
    @page_sequence ||= journey.page_sequence_for_claim(
      current_claim,
      journey_session,
      session[:slugs],
      params[:slug]
    )
  end

  def prepend_view_path_for_journey
    prepend_view_path("app/views/#{current_journey_routing_name.underscore}")
  end

  def correct_journey_for_claim_in_progress?
    journey::POLICIES.include?(current_claim.policy)
  end

  def failed_details_check_with_teacher_id?
    !current_claim.details_check? && current_claim.logged_in_with_tid?
  end
end
