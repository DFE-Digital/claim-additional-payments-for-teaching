module Admin
  class ServiceAccessLinksController < BaseAdminController
    before_action :ensure_service_operator

    def show
      @service_access_code = Journeys::ServiceAccessCode.find params[:id]
    end

    def create
      journey_routing_name = params.expect("journey")

      journey = Journeys.for_routing_name(journey_routing_name)

      raise ActiveRecord::RecordNotFound unless journey

      code = Journeys::ServiceAccessCode.create!(journey: journey)

      redirect_to admin_service_access_link_path(code)
    end
  end
end
