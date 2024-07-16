module Admin
  class JourneyConfigurationsController < BaseAdminController
    helper_method :journey_configuration
    before_action :ensure_service_operator, :journey_configuration
    after_action :send_reminders, only: [:update]

    def index
      @journey_configurations = Journeys::Configuration.order(created_at: :desc)
    end

    def edit
      @csv_upload = Policies::LevellingUpPremiumPayments::AwardCsvImporter.new if journey_configuration.additional_payments?

      @upload_form = EligibleFeProvidersForm.new
      @download_form = EligibleFeProvidersForm.new
    end

    def update
      journey_configuration.update!(journey_configuration_params)
      redirect_to admin_journey_configurations_url
    end

    private

    def journey_configuration
      return unless params[:id].present?

      @journey_configuration ||= Journeys::Configuration.find(params[:id])
    end

    def journey_configuration_params
      params.require(:journey_configuration).permit(:availability_message, :open_for_submissions, :current_academic_year, :teacher_id_enabled)
    end

    def send_reminders
      return unless journey_configuration.open_for_submissions && journey_configuration.additional_payments?

      SendReminderEmailsJob.perform_later
    end
  end
end
