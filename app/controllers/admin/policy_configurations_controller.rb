module Admin
  class PolicyConfigurationsController < BaseAdminController
    helper_method :policy_configuration
    before_action :ensure_service_operator, :policy_configuration
    after_action :send_reminders, only: [:update]

    def index
      @policy_configurations = PolicyConfiguration.order(:policy_type)
    end

    def edit; end

    def update
      policy_configuration.update!(policy_configuration_params)
      redirect_to admin_policy_configurations_url
    end

    private

    def policy_configuration
      return unless params[:id].present?

      @policy_configuration ||= PolicyConfiguration.find(params[:id])
    end

    def policy_configuration_params
      params.require(:policy_configuration).permit(:availability_message, :open_for_submissions, :current_academic_year)
    end

    def send_reminders
      return unless policy_configuration.open_for_submissions && policy_configuration.early_career_payments?

      SendReminderEmailsJob.peform_later(policy_configuration.current_academic_year)
    end
  end
end
