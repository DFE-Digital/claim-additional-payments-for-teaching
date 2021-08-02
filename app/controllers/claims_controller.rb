class ClaimsController < BasePublicController
  include PartOfClaimJourney
  include OneTimePassword

  skip_before_action :send_unstarted_claiments_to_the_start, only: [:new, :create, :timeout]
  before_action :check_page_is_in_sequence, only: [:show, :update]
  before_action :update_session_with_current_slug, only: [:show]
  before_action :check_claim_not_in_progress, only: [:new]
  before_action :clear_claim_session, only: [:new]
  before_action :prepend_view_path_for_policy

  def new
    render first_template_in_sequence
  end

  def create
    current_claim.attributes = claim_params
    if current_claim.save(context: page_sequence.slugs.first.to_sym)
      session[:claim_id] = current_claim.to_param
      redirect_to claim_path(current_policy_routing_name, next_slug)
    else
      render first_template_in_sequence
    end
  end

  def show
    search_schools if params[:school_search]
    invalid_postcode if params[:slug] == "postcode-search" && params[:claim]
    render current_template
  end

  def postcode
    params[:claim][:postcode]
  end

  def invalid_postcode
    current_claim.errors.add(:postcode, "Enter a real postcode") if postcode.blank? || !UKPostcode.parse(postcode).full_valid?
  end

  def update
    current_claim.attributes = claim_params
    current_claim.reset_dependent_answers
    current_claim.eligibility.reset_dependent_answers
    one_time_password

    if current_claim.save(context: page_sequence.current_slug.to_sym)
      redirect_to claim_path(current_policy_routing_name, next_slug)
    else
      show
    end
  end

  def timeout
  end

  def existing_session
  end

  def start_new
    new_policy_description = translate("#{params[:policy].underscore}.claim_description")

    return redirect_to existing_session_path, alert: "Select yes if you want to start a claim #{new_policy_description}" unless params[:start_new_claim].present?

    if ActiveModel::Type::Boolean.new.cast(params[:start_new_claim]) == true
      clear_claim_session
      redirect_to(new_claim_path(params[:policy]))
    else
      redirect_to(claim_path(current_claim.policy.routing_name, slug: session[:current_slug]))
    end
  end

  private

  helper_method :next_slug
  def next_slug
    page_sequence.next_slug
  end

  def search_schools
    schools = ActiveModel::Type::Boolean.new.cast(params[:exclude_closed]) ? School.open : School
    @schools = schools.search(params[:school_search])
  rescue ArgumentError => e
    raise unless e.message == School::SEARCH_NOT_ENOUGH_CHARACTERS_ERROR

    current_claim.errors.add(:school_search, "Enter the name or postcode of the school")
  end

  def claim_params
    params.fetch(:claim, {}).permit(Claim::PermittedParameters.new(current_claim).keys)
  end

  def current_template
    page_sequence.current_slug.underscore
  end

  def first_template_in_sequence
    page_sequence.slugs.first.underscore
  end

  def check_page_is_in_sequence
    raise ActionController::RoutingError.new("Not Found") unless page_sequence.in_sequence?(params[:slug])
  end

  def update_session_with_current_slug
    session[:current_slug] = params[:slug]
  end

  def check_claim_not_in_progress
    redirect_to(existing_session_path(policy: params[:policy])) if claim_in_progress?
  end

  def claim_in_progress?
    session[:claim_id].present? && !current_claim.eligibility.ineligible?
  end

  def page_sequence
    @page_sequence ||= PageSequence.new(current_claim, claim_slug_sequence, params[:slug])
  end

  def claim_slug_sequence
    current_claim.policy::SlugSequence.new(current_claim)
  end

  def prepend_view_path_for_policy
    prepend_view_path("app/views/#{current_policy_routing_name.underscore}")
  end

  def one_time_password
    case params[:slug]
    when "email-address"
      ClaimMailer.email_verification(current_claim, generate_otp).deliver_now
      session[:sent_one_time_password_at] = Time.now
    when "mobile-number"
      Rails.logger.debug "\n\n  ** =================== **\nSMS one_time_password: \n#{generate_otp}\n  ** =================== **\n"
    when "email-verification"
      current_claim.update_attributes(sent_one_time_password_at: session[:sent_one_time_password_at])
    end
  end

  def postcode
    params[:claim][:postcode]
  end

  def invalid_postcode
    current_claim.errors.add(:postcode, "Enter a real postcode") if postcode.blank? || !UKPostcode.parse(postcode).full_valid?
  end
end
