class ClaimsController < BasePublicController
  include PartOfClaimJourney
  include AddressDetails

  skip_before_action :send_unstarted_claimants_to_the_start, only: [:new, :create, :timeout]
  before_action :check_page_is_in_sequence, only: [:show, :update]
  before_action :update_session_with_current_slug, only: [:show]
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
    if params[:slug] == "postcode-search" && postcode
      redirect_to claim_path(current_policy_routing_name, "select-home-address", {"claim[postcode]": params[:claim][:postcode], "claim[address_line_1]": params[:claim][:address_line_1]}) and return unless invalid_postcode?
    elsif params[:slug] == "select-home-address" && postcode
      if address_data.nil?
        session[:claim_postcode] = params[:claim][:postcode]
        session[:claim_address_line_1] = params[:claim][:address_line_1]
        redirect_to claim_path(current_policy_routing_name, "no-address-found") and return
      end
    end

    render current_template
  end

  def update
    if params[:slug] == "personal-details"
      check_date_params
    else
      current_claim.attributes = claim_params
    end

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

  def persist
    current_claim.attributes = claim_params

    current_claim.save!
    session[:claim_id] = current_claim.to_param
    redirect_to claim_path(current_policy_routing_name, page_sequence.slugs.first.to_sym)
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
      ClaimMailer.email_verification(current_claim, otp.code).deliver_now if current_claim.valid?(:"email-address")
      session[:sent_one_time_password_at] = Time.now
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
end
