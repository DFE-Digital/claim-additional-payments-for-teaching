class ClaimsController < BasePublicController
  include PartOfClaimJourney
  include AddressDetails

  skip_before_action :send_unstarted_claimants_to_the_start, only: [:new, :create, :timeout]
  before_action :check_and_reset_if_new_tid_user_info
  before_action :initialize_session_slug_history
  before_action :check_page_is_in_sequence, only: [:show, :update]
  before_action :update_session_with_current_slug, only: [:update]
  before_action :set_backlink_path, only: [:show]
  before_action :check_claim_not_in_progress, only: [:new]
  before_action :clear_claim_session, only: [:new]
  before_action :prepend_view_path_for_journey

  def new
    persist
  end

  def create
    persist
  end

  def show
    search_schools if params[:school_search]

    if params[:slug] == "teacher-detail"
      save_and_set_teacher_id_user_info
    elsif params[:slug] == "qualification-details"
      return redirect_to claim_path(current_journey_routing_name, next_slug) if current_claim.has_no_dqt_data_for_claim?
    elsif params[:slug] == "teaching-subject-now" && no_eligible_itt_subject?
      return redirect_to claim_path(current_journey_routing_name, "eligible-itt-subject")
    elsif params[:slug] == "sign-in-or-continue"
      update_session_with_current_slug

      return skip_teacher_id if !journey_configuration.teacher_id_enabled?
    elsif params[:slug] == "select-email"
      session[:email_address] = current_claim.teacher_id_user_info["email"]
    elsif params[:slug] == "correct-school"
      update_session_with_tps_school(current_claim.recent_tps_school)
    elsif params[:slug] == "nqt-in-academic-year-after-itt" && page_sequence.in_sequence?("correct-school")
      @backlink_path = claim_path(current_journey_routing_name, "correct-school")
    elsif params[:slug] == "select-claim-school"
      update_session_with_tps_school(current_claim.tps_school_for_student_loan_in_previous_financial_year)
    elsif params[:slug] == "subjects-taught" && page_sequence.in_sequence?("select-claim-school")
      @backlink_path = claim_path(current_journey_routing_name, "select-claim-school")
    elsif params[:slug] == "select-mobile"
      session[:phone_number] = current_claim.teacher_id_user_info["phone_number"]
    elsif params[:slug] == "postcode-search" && postcode
      redirect_to claim_path(current_journey_routing_name, "select-home-address", {"claim[postcode]": params[:claim][:postcode], "claim[address_line_1]": params[:claim][:address_line_1]}) and return unless invalid_postcode?
    elsif params[:slug] == "select-home-address" && postcode
      session[:claim_postcode] = params[:claim][:postcode]
      session[:claim_address_line_1] = params[:claim][:address_line_1]
      if address_data.nil?
        redirect_to claim_path(current_journey_routing_name, "no-address-found") and return
      else
        # otherwise it takes you to "no-address-found" on the backlink from the slug sequence
        @backlink_path = claim_path(current_journey_routing_name, "postcode-search")
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
    redirect_to claim_path(current_journey_routing_name, "address")
  end

  def update
    case params[:slug]
    when "sign-in-or-continue"
      return skip_teacher_id
    when "teacher-detail"
      save_details_check
      Dqt::RetrieveClaimQualificationsData.call(current_claim) if current_claim.details_check?
    when "nqt-in-academic-year-after-itt"
      current_claim.attributes = claim_params
      determine_induction_answer_from_dqt_record if current_journey_routing_name == "additional-payments"
    when "qualification-details"
      set_dqt_data_as_answers
    when "personal-details"
      check_date_params
    when "eligibility-confirmed"
      return select_claim if current_journey_routing_name == "additional-payments"
    when "personal-bank-account", "building-society-account"
      return bank_account
    when "correct-school"
      check_correct_school_params
    when "select-claim-school"
      check_select_claim_school_params
    when "select-email"
      check_email_params
    when "select-mobile"
      check_mobile_number_params
    when "still-teaching"
      check_still_teaching_params
    else
      current_claim.attributes = claim_params

      # If some DQT data was missing and the user fills them manually we need
      # to re-populate those answers which depend on the manually-entered answer
      set_dqt_data_as_answers if current_claim.qualifications_details_check
    end

    current_claim.reset_dependent_answers unless params[:slug] == "select-email" || params[:slug] == "select-mobile"
    current_claim.reset_eligibility_dependent_answers(reset_attrs) unless params[:slug] == "qualification-details"
    one_time_password

    if current_claim.save(context: page_sequence.current_slug.to_sym)
      retrieve_student_loan_details
      redirect_to claim_path(current_journey_routing_name, next_slug)
    else
      show
    end
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

  helper_method :next_slug
  def next_slug
    page_sequence.next_slug
  end

  def redirect_to_existing_claim_journey
    new_journey = Journeys.for_policy(current_claim.policy)
    new_claim_slug_sequence = new_journey.slug_sequence.new(current_claim)
    new_page_sequence = PageSequence.new(current_claim, new_claim_slug_sequence, session[:slugs], params[:slug])
    redirect_to(claim_path(new_journey::ROUTING_NAME, slug: new_page_sequence.next_required_slug))
  end

  def set_backlink_path
    previous_slug = previous_slug()
    @backlink_path = claim_path(current_journey_routing_name, previous_slug) if previous_slug.present?
  end

  def previous_slug
    page_sequence.previous_slug
  end

  def persist
    current_claim.attributes = claim_params

    current_claim.save!
    session[:claim_id] = current_claim.claim_ids
    redirect_to claim_path(current_journey_routing_name, page_sequence.slugs.first.to_sym)
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

    redirect_to claim_path(current_journey_routing_name, slug_to_redirect_to) unless page_sequence.has_completed_journey_until?(params[:slug])
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
    redirect_to(existing_session_path(journey: current_journey_routing_name)) if claim_in_progress?
  end

  def claim_in_progress?
    session[:claim_id].present? && !current_claim.ineligible?
  end

  def page_sequence
    @page_sequence ||= PageSequence.new(current_claim, claim_slug_sequence, session[:slugs], params[:slug])
  end

  def claim_slug_sequence
    journey.slug_sequence.new(current_claim)
  end

  def prepend_view_path_for_journey
    prepend_view_path("app/views/#{current_journey_routing_name.underscore}")
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

    redirect_to claim_path(current_journey_routing_name, next_slug)
  end

  def bank_account
    @form = BankDetailsForm.new(claim_params.merge(claim: current_claim, hmrc_validation_attempt_count: session[:bank_validation_attempt_count]))

    @form.validate!

    current_claim.attributes = claim_params.merge({hmrc_bank_validation_succeeded: @form.hmrc_api_validation_succeeded?})
    current_claim.save!(context: page_sequence.current_slug.to_sym)

    redirect_to claim_path(current_journey_routing_name, next_slug)
  rescue ActiveModel::ValidationError
    current_claim.attributes = claim_params
    session[:bank_validation_attempt_count] = (session[:bank_validation_attempt_count] || 1) + 1 if @form.hmrc_api_validation_attempted?
    show
  end

  def correct_policy_namespace?
    Journeys.for_routing_name(current_journey_routing_name)::POLICIES.include?(current_claim.policy)
  end

  def failed_details_check_with_teacher_id?
    !current_claim.details_check? && current_claim.logged_in_with_tid?
  end

  def passed_details_check_with_teacher_id?
    current_claim.logged_in_with_tid? && current_claim.details_check?
  end

  def no_eligible_itt_subject?
    !current_claim.eligible_itt_subject
  end

  # NOTE: needs to be done before the slug_sequence is generated.
  # `logged_in_with_tid: false` means the user had pressed "Continue without signing in", reset it to `true`.
  # `logged_in_with_tid: false` is used to reject "teacher-details" and "qualification-details" from the slug_sequence.
  # Handles user somehow using Back button to go back and choose "Continue with DfE Identity" option.
  # Or they sign in a second time, `details_check` needs resetting in case details are different.
  def check_and_reset_if_new_tid_user_info
    DfeIdentity::ClaimUserDetailsReset.call(current_claim, :new_user_info) if session[:user_info]
  end

  def save_and_set_teacher_id_user_info
    @teacher_id_user_info = session[:user_info]
    if @teacher_id_user_info
      current_claim.update(teacher_id_user_info: @teacher_id_user_info)
      session.delete(:user_info)
    end
    set_teacher_id_user_info
  end

  def set_teacher_id_user_info
    @teacher_id_user_info ||= current_claim.teacher_id_user_info
  end

  def save_details_check
    details_check = params.dig(:claim, :details_check)
    DfeIdentity::ClaimUserDetailsCheck.call(current_claim, details_check)
  end

  def check_email_params
    current_claim.attributes = SelectEmailForm.extract_attributes(current_claim, email_address_check: params.dig(:claim, :email_address_check))
  end

  def check_mobile_number_params
    current_claim.attributes = SelectMobileNumberForm.extract_attributes(current_claim, mobile_check: params.dig(:claim, :mobile_check))
  end

  def update_session_with_tps_school(school)
    if school
      session[:tps_school_id] = school.id
      session[:tps_school_name] = school.name
      session[:tps_school_address] = school.address
    end
  end

  def check_correct_school_params
    updated_claim_params = CorrectSchoolForm.extract_params(claim_params, change_school: params[:change_school])
    current_claim.attributes = updated_claim_params
  end

  def check_select_claim_school_params
    updated_claim_params = SelectClaimSchoolForm.extract_params(claim_params, change_school: params[:additional_school])
    current_claim.attributes = updated_claim_params
  end

  def check_still_teaching_params
    updated_claim_params = StillTeachingForm.extract_params(claim_params)
    current_claim.attributes = updated_claim_params
  end

  def skip_teacher_id
    DfeIdentity::ClaimUserDetailsReset.call(current_claim, :skipped_tid)
    redirect_to claim_path(current_journey_routing_name, next_slug)
  end

  def determine_induction_answer_from_dqt_record
    return unless passed_details_check_with_teacher_id?

    # We can derive the induction_completed value for current_claim using the ECP DQT record
    # Remember: even if it's only relevant to ECP, the induction question is asked at the beginning
    # of the combined journey, and the applicant may end up applying for ECP or LUPP only at a later
    # stage in the journey, hence we need to store the answer on both eligibilities.
    induction_completed = current_claim.for_policy(Policies::EarlyCareerPayments).dqt_teacher_record&.eligible_induction?
    current_claim.attributes = claim_params.merge!({eligibility_attributes: {induction_completed:}})
  end

  def set_dqt_data_as_answers
    current_claim.attributes = claim_params
    current_claim.claims.each { |claim| claim.eligibility.set_qualifications_from_dqt_record }
  end

  def journey
    Journeys.for_routing_name(current_journey_routing_name)
  end

  def journey_configuration
    journey.configuration
  end

  def retrieve_student_loan_details
    # student loan details are retrieved every time the user confirms their details
    return unless ["personal-details", "teacher-detail"].include?(params[:slug])

    ClaimStudentLoanDetailsUpdater.call(current_claim)
  end
end
