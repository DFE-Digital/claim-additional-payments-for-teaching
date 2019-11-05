class ApplicationController < ActionController::Base
  CLAIM_TIMEOUT_LENGTH_IN_MINUTES = 30
  CLAIM_TIMEOUT_WARNING_LENGTH_IN_MINUTES = 2

  http_basic_authenticate_with(
    name: ENV["BASIC_AUTH_USERNAME"],
    password: ENV["BASIC_AUTH_PASSWORD"],
    if: -> { ENV["BASIC_AUTH_USERNAME"].present? },
  )

  helper_method :current_policy_routing_name, :claim_timeout_in_minutes, :timeout_warning_in_minutes
  before_action :end_expired_claim_sessions
  after_action :update_last_seen_at

  private

  def current_policy_routing_name
    params[:policy]
  end

  def claim_timeout_in_minutes
    self.class::CLAIM_TIMEOUT_LENGTH_IN_MINUTES
  end

  def timeout_warning_in_minutes
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

  def update_last_seen_at
    session[:last_seen_at] = Time.zone.now
  end
end
