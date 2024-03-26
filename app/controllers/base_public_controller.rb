class BasePublicController < ApplicationController
  include DfE::Analytics::Requests
  include ClaimSessionTimeout
  include HttpAuthConcern
  include JourneyConcern

  helper_method :claim_timeout_in_minutes
  before_action :add_view_paths
  before_action :end_expired_claim_sessions
  after_action :update_last_seen_at

  private

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
    prepend_view_path(Rails.root.join("app", "views", journey::VIEW_PATH))
  end
end
