module Admin
  class PolicyConfigurationsController < BaseAdminController
    before_action :ensure_service_operator

    def index
      @policy_configurations = PolicyConfiguration.order(:policy_type)
    end

    def edit
      @policy_configuration = PolicyConfiguration.find(params[:id])
    end

    def update
      policy_configuration = PolicyConfiguration.find(params[:id])
      policy_configuration.update!(policy_configuration_params)

      redirect_to admin_policy_configurations_url
    end

    private

    def policy_configuration_params
      params.require(:policy_configuration).permit(:availability_message, :open_for_submissions, :current_academic_year)
    end
  end
end
