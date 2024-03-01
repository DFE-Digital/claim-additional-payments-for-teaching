class BasePublicController < ApplicationController
  include DfE::Analytics::Requests
  include ClaimSessionTimeout
  include HttpAuthConcern

  helper_method :current_policy, :current_policy_routing_name, :claim_timeout_in_minutes
  before_action :add_view_paths
  before_action :end_expired_claim_sessions
  after_action :update_last_seen_at

  private

  def current_policy
    JourneyConfiguration.policy_for_routing_name(current_policy_routing_name)
  end
  helper_method :current_policy

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

  def add_view_paths
    path = JourneyConfiguration.view_path(current_policy_routing_name)
    prepend_view_path(Rails.root.join("app", "views", path)) if path
  end
end
