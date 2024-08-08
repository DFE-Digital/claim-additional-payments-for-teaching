module ThirdParties
  class BaseController < ApplicationController
    include DfE::Analytics::Requests
    include HttpAuthConcern

    before_action :add_view_paths

    private

    def third_party_session
      @third_party_session ||= journey::ThirdPartySession.from_session(
        session[journey::ThirdPartySession.session_key] || {}
      )
    end

    def journey
      @journey ||= Journeys.for_routing_name(params[:journey])
    end

    def add_view_paths
      prepend_view_path(Rails.root.join("app", "views", journey::VIEW_PATH))
    end

    def current_journey_routing_name
      journey::ROUTING_NAME
    end

    helper_method :current_journey_routing_name
  end
end
