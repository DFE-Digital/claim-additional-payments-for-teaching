class ApplicationController < ActionController::Base
  CLAIM_TIMEOUT_LENGTH_IN_MINUTES = 30
  CLAIM_TIMEOUT_WARNING_LENGTH_IN_MINUTES = 2

  http_basic_authenticate_with(
    name: ENV["BASIC_AUTH_USERNAME"],
    password: ENV["BASIC_AUTH_PASSWORD"],
    if: -> { ENV.key?("BASIC_AUTH_USERNAME") },
  )

  helper_method :signed_in?, :current_claim
  before_action :end_expired_claim_sessions
  before_action :update_last_seen_at

  private

  def send_unstarted_claiments_to_the_start
    redirect_to root_url unless current_claim.present?
  end

  def signed_in?
    session.key?(:login)
  end

  def current_claim
    @current_claim ||= Claim.find(session[:claim_id]) if session.key?(:claim_id)
  end

  def end_expired_claim_sessions
    if claim_session_timed_out?
      clear_claim_session
      redirect_to timeout_claim_path
    end
  end

  def claim_session_timed_out?
    session.key?(:claim_id) &&
      session.key?(:last_seen_at) &&
      session[:last_seen_at] < CLAIM_TIMEOUT_LENGTH_IN_MINUTES.minutes.ago
  end

  def clear_claim_session
    session.delete(:claim_id)
    session.delete(:last_seen_at)
    session.delete(:verify_request_id)
  end

  def update_last_seen_at
    session[:last_seen_at] = Time.zone.now
  end
end
