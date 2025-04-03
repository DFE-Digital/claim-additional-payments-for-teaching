class BasePublicController < ApplicationController
  include DfE::Analytics::Requests
  include HttpAuthConcern
  include JourneyConcern

  before_action :add_view_paths
  after_action :update_last_seen_at

  private

  def clear_claim_session
    session.delete(:slugs)
    clear_journey_sessions!
  end

  def update_last_seen_at
    session[:last_seen_at] = Time.zone.now
  end

  def add_view_paths
    prepend_view_path(Rails.root.join("app", "views", journey::VIEW_PATH))
  end
end
