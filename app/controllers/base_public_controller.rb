class BasePublicController < ApplicationController
  include DfE::Analytics::Requests
  include HttpAuthConcern
  include JourneyConcern

  before_action :add_view_paths

  private

  def clear_claim_session
    clear_journey_session!
  end

  def add_view_paths
    prepend_view_path(Rails.root.join("app", "views", journey.view_path))
  end
end
