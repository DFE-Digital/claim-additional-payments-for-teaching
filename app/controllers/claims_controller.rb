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
  before_action :prepend_view_path_for_policy

  def new
    persist
  end

  def create
    persist
  end

  def show
    search_schools if params[:school_search]
    if params[:slug] == "teaching-subject-now" && !current_claim.eligibility.eligible_itt_subject
      return redirect_to claim_path(current_policy_routing_name, "eligible-itt-subject")
    elsif params[:slug] == "postcode-search" && postcode
      redirect_to claim_path(current_policy_routing_name, "select-home-address", {"claim[postcode]": params[:claim][:postcode], "claim[address_line_1]": params[:claim][:address_line_1]}) and return unless invalid_postcode?
    elsif params[:slug] == "select-home-address" && postcode
      session[:claim_postcode] = params[:claim][:postcode]
      session[:claim_address_line_1] = params[:claim][:address_line_1]
      if address_data.nil?
        redirect_to claim_path(current_policy_routing_name, "no-address-found") and return
      else
        # otherwise it takes you to "no-address-found" on the backlink from the slug sequence
        @backlink_path = claim_path(current_policy_routing_name, "postcode-search")
      end
    elsif params[:slug] == "select-home-address" && !postcode.present?
      session[:claim_postcode] = nil
      session[:claim_address_line_1] = nil
      redirect_to claim_path(current_policy_routing_name, "postcode-search") and return
    elsif ["personal-bank-account", "building-society-account"].include?(params[:slug])
      @form ||= BankDetailsForm.new(claim: current_claim)
    end

    render current_template
  rescue OrdnanceSurvey::Client::ResponseError => e
    Rollbar.error(e)
    flash[:notice] = "Please enter your address manually"
    redirect_to claim_path(current_policy_routing_name, "address")
  end

  def update
    case params[:slug]
    when "personal-details"
      check_date_params
    when "eligibility-confirmed"
      return select_claim if current_policy_routing_name == "additional-payments"
    when "personal-bank-account", "building-society-account"
      return bank_account
    else
      current_claim.attributes = claim_params
    end

    current_claim.reset_dependent_answers
    current_claim.reset_eligibility_dependent_answers(reset_attrs)
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
      redirect_to(claim_path(current_claim.policy.routing_name, slug: slug_to_redirect_to))
    end
  end

  private

  helper_method :next_slug
  def next_slug
    page_sequence.next_slug
  end

  def set_backlink_path
    previous_slug = previous_slug()
    @backlink_path = claim_path(current_policy_routing_name, previous_slug) if previous_slug.present?
  end

  def previous_slug
    page_sequence.previous_slug
  end

  def persist
    current_claim.attributes = claim_params

    current_claim.save!
    session[:claim_id] = current_claim.claim_ids
    redirect_to claim_path(current_policy_routing_name, page_sequence.slugs.first.to_sym)
  end

  def search_schools
    @backlink_path = page_sequence.current_slug
    schools = ActiveModel::Type::Boolean.new.cast(params[:exclude_closed]) ? School.open : School
    @schools = schools.search(params[:school_search])
  rescue ArgumentError => e
    raise unless e.message == School::SEARCH_NOT_ENOUGH_CHARACTERS_ERROR

    current_claim.errors.add(:school_search, "Enter a school or postcode")
  end

  def claim_params
    params.fetch(:claim, {}).permit(Claim::PermittedParameters.new(current_claim).keys)
  end

  def check_date_params
    dob_params = {
      "date_of_birth_day" => claim_params.dig("date_of_birth(3i)").to_s,
      "date_of_birth_month" => claim_params.dig("date_of_birth(2i)").to_s,
      "date_of_birth_year" => claim_params.dig("date_of_birth(1i)").to_s
    }
    current_claim.attributes = claim_params.merge!(dob_params)
  rescue ActiveRecord::MultiparameterAssignmentErrors
    current_claim.attributes = claim_params.except("date_of_birth(3i)", "date_of_birth(2i)", "date_of_birth(1i)") if params[:slug] == "personal-details"
  end

  def current_template
    page_sequence.current_slug.underscore
  end

  def check_page_is_in_sequence
    unless correct_policy_namespace?
      clear_claim_session
      return redirect_to new_claim_path
    end

    raise ActionController::RoutingError.new("Not Found") unless page_sequence.in_sequence?(params[:slug])

    redirect_to claim_path(current_policy_routing_name, slug_to_redirect_to) unless page_sequence.has_completed_journey_until?(params[:slug])
  end

  def initialize_session_slug_history
    session[:slugs] ||= []
  end

  def update_session_with_current_slug
    session[:slugs] << params[:slug] unless PageSequence::DEAD_END_SLUGS.include?(params[:slug])
  end

  def slug_to_redirect_to
    page_sequence.next_required_slug
  end

  def check_claim_not_in_progress
    redirect_to(existing_session_path(policy: params[:policy])) if claim_in_progress?
  end

  def claim_in_progress?
    session[:claim_id].present? && !current_claim.ineligible?
  end

  def page_sequence
    set_session
    default_params = [current_claim, claim_slug_sequence, session[:slugs], params[:slug]]

    @page_sequence = PageSequence.new(*default_params, params[:editible_answer].present?)
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
      if current_claim.valid?(:"email-address")
        ClaimMailer.email_verification(current_claim, otp.code).deliver_now
        session[:sent_one_time_password_at] = Time.now
      end
    when "mobile-number"
      if current_claim.valid?(:"mobile-number") && current_claim.mobile_number_changed?
        response = NotifySmsMessage.new(
          phone_number: current_claim.mobile_number,
          template_id: "86ae1fe4-4f98-460b-9d57-181804b4e218",
          personalisation: {
            otp: otp.code
          }
        ).deliver!
      end
      session[:sent_one_time_password_at] = Time.now unless response.nil?
    when "email-verification"
      current_claim.update(sent_one_time_password_at: session[:sent_one_time_password_at], one_time_password_category: :claim_email)
    when "mobile-verification"
      current_claim.update(sent_one_time_password_at: session[:sent_one_time_password_at], one_time_password_category: :claim_mobile)
    end
  end

  def otp
    @otp ||= OneTimePassword::Generator.new
  end

  def reset_attrs
    return [] unless claim_params["eligibility_attributes"]

    claim_params["eligibility_attributes"].keys
  end

  def select_claim
    policy = params.fetch(:claim, {}).permit(:policy)[:policy]

    unless policy
      current_claim.errors.add(:policy, "Select an additional payment")
      return show
    end

    session[:selected_claim_policy] = policy

    redirect_to claim_path(current_policy_routing_name, next_slug)
  end

  def bank_account
    @form = BankDetailsForm.new(claim_params.merge(claim: current_claim, hmrc_validation_attempt_count: session[:bank_validation_attempt_count]))

    @form.validate!

    current_claim.attributes = claim_params.merge({hmrc_bank_validation_succeeded: @form.hmrc_api_validation_succeeded?})
    current_claim.save!(context: page_sequence.current_slug.to_sym)

    redirect_to claim_path(current_policy_routing_name, next_slug)
  rescue ActiveModel::ValidationError
    current_claim.attributes = claim_params
    session[:bank_validation_attempt_count] = (session[:bank_validation_attempt_count] || 1) + 1 if @form.hmrc_api_validation_attempted?
    show
  end

  def correct_policy_namespace?
    PolicyConfiguration.policies_for_routing_name(params[:policy]).include?(current_claim.policy)
  end

  def set_session
    session[:slugs] ||= []
    session[:slugs].concat(["qualification", "itt-year", "eligible-itt-subject"]) if params[:test]
  end
end
