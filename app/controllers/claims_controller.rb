class ClaimsController < BasePublicController
  include PartOfClaimJourney
  include AddressDetails

  skip_before_action :send_unstarted_claimants_to_the_start, only: [:new, :create, :timeout]
  before_action :initialize_session_slug_history
  before_action :check_page_is_in_sequence, only: [:show, :update]
  before_action :update_session_with_current_slug, only: [:update]
  before_action :set_backlink_path, only: [:show]
  before_action :check_claim_not_in_progress, only: [:new]
  before_action :clear_claim_session, only: [:new]
  before_action :prepend_view_path_for_journey

  helper_method :next_slug

  def new
    persist
  end

  def create
    persist
  end

  def show
    if params[:slug] == "teaching-subject-now" && no_eligible_itt_subject?
      return redirect_to claim_path(current_journey_routing_name, "eligible-itt-subject")
    end

    if params[:slug] == "qualification-details"
      return redirect_to claim_path(current_journey_routing_name, next_slug) if current_claim.has_no_dqt_data_for_claim?
    end

    # TODO: Migrate the remaining slugs to form objects.
    if @form ||= journey.form(claim: current_claim, journey_session:, params:)
      set_any_backlink_override
      render current_template
      return
    end

    if params[:slug] == "select-home-address" && postcode
      session[:claim_postcode] = postcode
      session[:claim_address_line_1] = params.dig(:claim, :address_line_1)
      if address_data.nil?
        redirect_to claim_path(current_journey_routing_name, "no-address-found") and return
      else
        # otherwise it takes you to "no-address-found" on the backlink from the slug sequence
        @backlink_path = claim_path(current_journey_routing_name, "postcode-search")
      end
    elsif params[:slug] == "select-home-address" && !postcode.present?
      session[:claim_postcode] = nil
      session[:claim_address_line_1] = nil
      redirect_to claim_path(current_journey_routing_name, "postcode-search") and return
    end

    render current_template
  rescue OrdnanceSurvey::Client::ResponseError => e
    Rollbar.error(e)
    flash[:notice] = "Please enter your address manually"
    redirect_to claim_path(current_journey_routing_name, "address")
  end

  def update
    params[:claim][:hmrc_validation_attempt_count] = session[:hmrc_validation_attempt_count] || 0 if on_banking_page?

    # TODO: Migrate the remaining slugs to form objects.
    if (@form = journey.form(claim: current_claim, journey_session:, params:))
      if @form.save
        retrieve_student_loan_details
        update_session_with_selected_policy
        redirect_to claim_path(current_journey_routing_name, next_slug)
      else
        session[:hmrc_validation_attempt_count] = (session[:hmrc_validation_attempt_count] || 0) + 1 if on_banking_page? && @form.hmrc_api_validation_attempted?
        set_any_backlink_override
        show
      end

      return
    end

    current_claim.attributes = claim_params
    current_claim.reset_dependent_answers unless params[:slug] == "select-mobile"
    current_claim.reset_eligibility_dependent_answers(reset_attrs) unless params[:slug] == "qualification-details"

    if current_claim.save(context: page_sequence.current_slug.to_sym)
      retrieve_student_loan_details
      redirect_to claim_path(current_journey_routing_name, next_slug)
    else
      show
    end
  rescue OrdnanceSurvey::Client::ResponseError => e
    Rollbar.error(e)
    flash[:notice] = "Please enter your address manually"
    redirect_to claim_path(current_journey_routing_name, "address")
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

  def next_slug
    page_sequence.next_slug
  end

  def redirect_to_existing_claim_journey
    new_journey = Journeys.for_policy(current_claim.policy)
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

  def set_any_backlink_override
    @backlink_path = @form.backlink_path if @form.backlink_path
  end

  def update_session_with_selected_policy
    # The following is a journey-specific behaviour that cannot be encapsulated inside
    # the relevant form. The claimant answers are stored on the claim in the database,
    # but `selected_claim_policy` is not an answer we need to persist, not at the moment.
    # TODO: revisit this once the claimant's answers are all moved to the session, as at
    # that point we can probably encapsulate this behaviour somewhere else
    if current_journey_routing_name == "additional-payments" && params[:slug] == "eligibility-confirmed"
      session[:selected_claim_policy] = @form.selected_claim_policy
    end
  end

  def previous_slug
    page_sequence.previous_slug
  end

  def persist
    current_claim.attributes = claim_params

    current_claim.save!
    session[:claim_id] = current_claim.claim_ids
    session[journey_session_key] = journey_session.id
    redirect_to claim_path(current_journey_routing_name, page_sequence.slugs.first.to_sym)
  end

  def claim_params
    params.fetch(:claim, {}).permit(Claim::PermittedParameters.new(current_claim).keys)
  end

  def current_template
    page_sequence.current_slug.underscore
  end

  def check_page_is_in_sequence
    unless correct_journey_for_claim_in_progress?
      clear_claim_session
      return redirect_to new_claim_path
    end

    raise ActionController::RoutingError.new("Not Found") unless page_sequence.in_sequence?(params[:slug])

    redirect_to claim_path(current_journey_routing_name, slug_to_redirect_to) unless page_sequence.has_completed_journey_until?(params[:slug])
  end

  def initialize_session_slug_history
    session[:slugs] ||= []
  end

  def update_session_with_current_slug
    session[:slugs] << params[:slug] unless Journeys::PageSequence::DEAD_END_SLUGS.include?(params[:slug])
  end

  def slug_to_redirect_to
    page_sequence.next_required_slug
  end

  def check_claim_not_in_progress
    redirect_to(existing_session_path(journey: current_journey_routing_name)) if claim_in_progress?
  end

  def claim_in_progress?
    session[:claim_id].present? && !current_claim.ineligible?
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

  def on_banking_page?
    %w[personal-bank-account building-society-account].include?(params[:slug])
  end

  def reset_attrs
    return [] unless claim_params["eligibility_attributes"]

    claim_params["eligibility_attributes"].keys
  end

  def correct_journey_for_claim_in_progress?
    journey::POLICIES.include?(current_claim.policy)
  end

  def failed_details_check_with_teacher_id?
    !current_claim.details_check? && current_claim.logged_in_with_tid?
  end

  def no_eligible_itt_subject?
    !current_claim.eligible_itt_subject
  end

  def retrieve_student_loan_details
    # student loan details are currently retrieved for TSLR and ECP/LUPP journeys only
    return unless ["student-loans", "additional-payments"].include?(current_journey_routing_name)

    # Applicants' student loan details must be retrieved any time their personal details are
    # updated using the `personal-details` page. This is normally the case when using the non-TID
    # route, or when using the TID-route but not all personal details came through/are valid.
    # For claims being submitted using the TID-route and where all personal details came through/are
    # valid, the student loan details must be retrieved after the `information-provided` page instead.
    if params[:slug] == "personal-details" || (params[:slug] == "information-provided" &&
        current_claim.logged_in_with_tid? && current_claim.all_personal_details_same_as_tid?)
      ClaimStudentLoanDetailsUpdater.call(current_claim)
    end
  end
end
