module ThirdParties
  class SessionsController < ApplicationController
    include DfE::Analytics::Requests
    include HttpAuthConcern

    before_action :add_view_paths

    def new
    end

    def callback
      third_party_session = journey::ThirdPartySession.from_omniauth(
        request.env["omniauth.auth"]
      )

      # Ideally we'd have a record in the db but can get away without one
      # so long as we're not storing too much in the session.
      session[journey::ThirdPartySession.session_key] = third_party_session.to_h

      redirect_to session.delete(:after_sign_in_path)
    end

    private

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

