class BasePublicController < ApplicationController
  include DfE::Analytics::Requests
  include ClaimSessionTimeout
  include HttpAuthConcern

  helper_method :current_journey_routing_name, :claim_timeout_in_minutes
  before_action :add_view_paths
  before_action :end_expired_claim_sessions
  after_action :update_last_seen_at

  private

  def current_journey_routing_name
    params[:journey]
  end

  def end_expired_claim_sessions
    if claim_session_timed_out?
      clear_claim_session
      redirect_to timeout_claim_path(current_journey_routing_name)
    end
  end

  def update_last_seen_at
    session[:last_seen_at] = Time.zone.now
  end

  def add_view_paths
    path = JourneyConfiguration.view_path(current_journey_routing_name)
    prepend_view_path(Rails.root.join("app", "views", path)) if path
  end
end
