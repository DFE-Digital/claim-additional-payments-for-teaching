class BasePublicController < ApplicationController
  CLAIM_TIMEOUT_LENGTH_IN_MINUTES = 30

  helper_method :current_policy_routing_name, :claim_timeout_in_minutes
  before_action :authenticate_with_basic_auth, if: :part_of_maths_and_physics_journey
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
      redirect_to timeout_claim_path(policy_routing_name_for_redirect)
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

  def authenticate_with_basic_auth
    if ENV["BASIC_AUTH_USERNAME"].present?
      authenticate_or_request_with_http_basic("Maths & Physics private beta") do |username, password|
        ActiveSupport::SecurityUtils.secure_compare(username, ENV["BASIC_AUTH_USERNAME"]) &&
          ActiveSupport::SecurityUtils.secure_compare(password, ENV["BASIC_AUTH_PASSWORD"])
      end
    end
  end

  def part_of_maths_and_physics_journey
    current_policy_routing_name == MathsAndPhysics.routing_name
  end
end
