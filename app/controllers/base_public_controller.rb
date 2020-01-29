class BasePublicController < ApplicationController
  include ClaimSessionTimeout

  helper_method :current_policy_routing_name, :claim_timeout_in_minutes
  before_action :end_expired_claim_sessions

  private

  def current_policy_routing_name
    params[:policy]
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
end
