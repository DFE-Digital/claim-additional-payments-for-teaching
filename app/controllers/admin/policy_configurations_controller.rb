module Admin
  class PolicyConfigurationsController < BaseAdminController
    helper_method :policy_configuration, :lupp_awards_last_updated_at, :lupp_awards_academic_years
    before_action :ensure_service_operator, :policy_configuration
    after_action :send_reminders, only: [:update]

    def index
      @policy_configurations = PolicyConfiguration.order(created_at: :desc)
    end

    def edit
    end

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
      return unless policy_configuration.open_for_submissions && policy_configuration.additional_payments?

      SendReminderEmailsJob.perform_later
    end

    def lupp_awards_last_updated_at
      LevellingUpPremiumPayments::Award.last_updated_at(@policy_configuration.current_academic_year) if @policy_configuration.additional_payments?
    end

    def lupp_awards_academic_years
      LevellingUpPremiumPayments::Award.distinct_academic_years if @policy_configuration.additional_payments?
    end
  end
end
