class ClaimsController < ApplicationController
  TIMEOUT_LENGTH_IN_MINUTES = 30
  TIMEOUT_WARNING_LENGTH_IN_MINUTES = 2

  before_action :send_unstarted_claiments_to_the_start, only: [:show, :update, :ineligible]
  before_action :end_expired_sessions
  before_action :update_last_seen_at

  after_action :clear_claim_session, if: :submission_complete?

  def new
  end

  def create
    claim = TslrClaim.create!
    session[:tslr_claim_id] = claim.to_param

    redirect_to claim_path("qts-year")
  end

  def show
    search_schools if params[:school_search]
    render claim_page_template
  end

  def update
    if update_current_claim!
      redirect_to next_claim_path
    else
      show
    end
  end

  def ineligible
  end

  def refresh_session
    head :ok
  end

  private

  def update_current_claim!
    if params[:slug] == "check-your-answers"
      current_claim.submit!
    else
      current_claim.attributes = claim_params
      current_claim.save(context: params[:slug].to_sym)
    end
  end

  def next_claim_path
    return ineligible_claim_path if current_claim.ineligible?
    return claim_path("check-your-answers") if edited_answer?

    claim_path(next_slug)
  end

  def edited_answer?
    current_claim.can_be_submitted? && !current_claim.submitted? && !on_school_flow?
  end

  def on_school_flow?
    return true if params[:slug] == "claim-school"
    return true if params[:slug] == "still-teaching" && current_claim.employment_status != "claim_school"
    false
  end

  def next_slug
    current_slug_index = current_claim.page_sequence.index(params[:slug])
    current_claim.page_sequence[current_slug_index + 1]
  end

  def submission_complete?
    params[:slug] == "confirmation" && current_claim.submitted?
  end

  def search_schools
    @schools = School.search(params[:school_search])
  rescue ArgumentError => e
    raise unless e.message == School::SEARCH_NOT_ENOUGH_CHARACTERS_ERROR

    current_claim.errors.add(:school_search, "Search for the school name with a minimum of four characters")
  end

  def claim_params
    params.require(:tslr_claim).permit(
      :qts_award_year,
      :claim_school_id,
      :employment_status,
      :current_school_id,
      :mostly_teaching_eligible_subjects,
      :full_name,
      :address_line_1,
      :address_line_2,
      :address_line_3,
      :address_line_4,
      :postcode,
      :date_of_birth,
      :teacher_reference_number,
      :national_insurance_number,
      :student_loan_repayment_amount,
      :email_address,
      :bank_sort_code,
      :bank_account_number,
    )
  end

  def claim_page_template
    params[:slug].underscore
  end

  def current_claim
    @current_claim ||= TslrClaim.find(session[:tslr_claim_id]) if session.key?(:tslr_claim_id)
  end
  helper_method :current_claim

  def send_unstarted_claiments_to_the_start
    redirect_to root_url unless current_claim.present?
  end

  def update_last_seen_at
    session[:last_seen_at] = Time.zone.now
  end

  def end_expired_sessions
    if claim_session_timed_out?
      clear_claim_session
      redirect_to timeout_claim_path
    end
  end

  def claim_session_timed_out?
    session.key?(:tslr_claim_id) &&
      session.key?(:last_seen_at) &&
      session[:last_seen_at] < TIMEOUT_LENGTH_IN_MINUTES.minutes.ago
  end

  def clear_claim_session
    session[:tslr_claim_id] = nil
    session[:last_seen_at] = nil
  end
end
