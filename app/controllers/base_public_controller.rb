class BasePublicController < ApplicationController
  include ClaimSessionTimeout

  helper_method :current_policy_routing_name, :claim_timeout_in_minutes
  before_action :end_expired_claim_sessions
  after_action :update_last_seen_at

  private

  def current_policy_routing_name
    params[:policy]
  end

  def end_expired_claim_sessions
    if claim_session_timed_out?
      policy_routing_name_for_redirect = current_policy_routing_name
      clear_claim_session
      redirect_to timeout_claim_path(policy_routing_name_for_redirect)
    end
  end

  def update_last_seen_at
    session[:last_seen_at] = Time.zone.now
  end
end
