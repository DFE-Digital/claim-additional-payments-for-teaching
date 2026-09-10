module Admin
  class JourneyFlowsController < BaseAdminController
    before_action :ensure_service_operator
    before_action -> { raise ActiveRecord::RecordNotFound if Rails.env.production? && !Rails.env.review_app_like? }

    def index
      @journeys = Journeys.landing_page_journeys
    end

    def show
      @journey = Journeys.all.find { |journey| journey.routing_name == params[:journey_key] }

      if @journey.blank?
        redirect_to admin_components_journey_flows_path, alert: "Journey not found"
        return
      end

      @journey_name = @journey.full_name
      @mermaid_diagram = JourneyFlowDefinition.mermaid_for(@journey.routing_name)
    end
  end
end
