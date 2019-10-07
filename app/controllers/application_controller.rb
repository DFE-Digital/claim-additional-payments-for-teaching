class ApplicationController < ActionController::Base
  CLAIM_TIMEOUT_LENGTH_IN_MINUTES = 30
  CLAIM_TIMEOUT_WARNING_LENGTH_IN_MINUTES = 2
  ADMIN_TIMEOUT_LENGTH_IN_MINUTES = 30

  http_basic_authenticate_with(
    name: ENV["BASIC_AUTH_USERNAME"],
    password: ENV["BASIC_AUTH_PASSWORD"],
    if: -> { ENV.key?("BASIC_AUTH_USERNAME") },
  )

  helper_method :admin_signed_in?, :current_claim, :claim_timeout_in_minutes, :claim_timeout_warning_in_minutes
  before_action :end_expired_admin_sessions
  before_action :end_expired_claim_sessions
  before_action :update_last_seen_at

  private

  def send_unstarted_claiments_to_the_start
    redirect_to root_url unless current_claim.persisted?
  end

  def admin_signed_in?
    session.key?(:user_id)
  end

  def current_claim
    @current_claim ||= current_claim_from_session || Claim.new(eligibility: StudentLoans::Eligibility.new)
  end

  def current_claim_from_session
    Claim.find(session[:claim_id]) if session.key?(:claim_id)
  end

  def claim_timeout_in_minutes
    self.class::CLAIM_TIMEOUT_LENGTH_IN_MINUTES
  end

  def claim_timeout_warning_in_minutes
    self.class::CLAIM_TIMEOUT_WARNING_LENGTH_IN_MINUTES
  end

  def end_expired_claim_sessions
    if claim_session_timed_out?
      clear_claim_session
      redirect_to timeout_claim_path
    end
  end

  def claim_session_timed_out?
    session.key?(:claim_id) && session[:last_seen_at] < claim_timeout_in_minutes.minutes.ago
  end

  def clear_claim_session
    session.delete(:claim_id)
    session.delete(:verify_request_id)
  end

  def admin_session_timed_out?
    admin_signed_in? && session[:last_seen_at] < ADMIN_TIMEOUT_LENGTH_IN_MINUTES.minutes.ago
  end

  def end_expired_admin_sessions
    if admin_session_timed_out?
      session.delete(:user_id)
      session.delete(:organisation_id)
      session.delete(:role_codes)
      flash[:notice] = "Your session has timed out due to inactivity, please sign-in again"
    end
  end

  def update_last_seen_at
    session[:last_seen_at] = Time.zone.now
  end
end
