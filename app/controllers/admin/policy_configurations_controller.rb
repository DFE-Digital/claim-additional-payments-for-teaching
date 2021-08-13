module Admin
  class PolicyConfigurationsController < BaseAdminController
    before_action :ensure_service_operator
    after_action :send_reminders, only: [:update]

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

    # This kicks off a job that will send reminder emails to all emails
    # present in the reminders table that have not yet had emails sent
    def send_reminders
      return unless policy_configuration.open_for_submissions
      
      
    end
  end
end
