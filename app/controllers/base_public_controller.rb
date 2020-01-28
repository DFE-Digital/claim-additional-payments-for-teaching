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
      policy_routing_name_for_redirect = current_policy_routing_name
      clear_claim_session
      respond_to do |format|
        format.html { redirect_to timeout_claim_path(policy_routing_name_for_redirect) }
        format.json do
          render json: {redirect: timeout_claim_path(policy_routing_name_for_redirect)}
        end
      end
    end
  end

  def claim_session_timed_out?
    session.key?(:claim_id) && session[:last_seen_at] < claim_timeout_in_minutes.minutes.ago
  end

  def clear_claim_session
    session.delete(:claim_id)
    session.delete(:verify_request_id)
    @current_claim = nil
  end
end
