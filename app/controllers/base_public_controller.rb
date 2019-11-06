class BasePublicController < ApplicationController
  CLAIM_TIMEOUT_LENGTH_IN_MINUTES = 30

  helper_method :current_policy_routing_name, :claim_timeout_in_minutes
  before_action :end_expired_claim_sessions

  private

  def current_policy_routing_name
    params[:policy]
  end

  def claim_timeout_in_minutes
    self.class::CLAIM_TIMEOUT_LENGTH_IN_MINUTES
  end

  def end_expired_claim_sessions
    if claim_session_timed_out?
      clear_claim_session
      redirect_to timeout_claim_path(current_policy_routing_name)
    end
  end

  def claim_session_timed_out?
    session.key?(:claim_id) && session[:last_seen_at] < claim_timeout_in_minutes.minutes.ago
  end

  def clear_claim_session
    session.delete(:claim_id)
    session.delete(:verify_request_id)
  end
end
