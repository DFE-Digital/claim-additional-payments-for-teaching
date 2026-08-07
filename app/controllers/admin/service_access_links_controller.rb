module Admin
  class ServiceAccessLinksController < BaseAdminController
    before_action :ensure_service_admin

    def show
      @service_access_code = Journeys::ServiceAccessCode.find params[:id]
    end

    def create
      journey_routing_name = service_access_link_params[:journey]

      journey = Journeys.for_routing_name(journey_routing_name)

      raise ActiveRecord::RecordNotFound unless journey

      code = Journeys::ServiceAccessCode.create!(
        journey: journey,
        multiuse: ActiveModel::Type::Boolean.new.cast(service_access_link_params[:multi_use]) || false
      )

      redirect_to admin_service_access_link_path(code)
    end

    private

    def service_access_link_params
      params.permit(:journey, :multi_use)
    end
  end
end
