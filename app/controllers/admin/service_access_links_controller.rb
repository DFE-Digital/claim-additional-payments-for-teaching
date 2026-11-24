module Admin
  class ServiceAccessLinksController < BaseAdminController
    PERMISSIONS = {
      "show" => "service_access_links.show",
      "create" => "service_access_links.create"
    }.freeze

    before_action :ensure_service_admin, unless: :admin_permissions_enabled?
    before_action :ensure_permitted, if: :admin_permissions_enabled?

    def show
      @service_access_code = Journeys::ServiceAccessCode.find params[:id]
    end

    def create
      journey_routing_name = service_access_link_params[:journey]

      journey = Journeys.for_routing_name(journey_routing_name)

      raise ActiveRecord::RecordNotFound unless journey

      multiuse = ActiveModel::Type::Boolean.new.cast(service_access_link_params[:multiuse]) || false
      code = Journeys::ServiceAccessCode.create!(journey: journey, multiuse: multiuse)

      redirect_to admin_service_access_link_path(code)
    end

    private

    def admin_permissions_enabled?
      FeatureFlag.enabled?(:admin_permissions)
    end

    def ensure_permitted
      return if current_admin.permitted?(PERMISSIONS.fetch(action_name))

      render "admin/auth/failure", status: :forbidden
    end

    def service_access_link_params
      params.permit(:journey, :multiuse)
    end
  end
end
