module Admin
  class JourneyConfigurationsController < BaseAdminController
    helper_method :journey_configuration
    before_action :ensure_service_operator, :journey_configuration
    after_action :send_reminders, only: [:update]

    FILE_UPLOAD_TARGET_DATA_MODELS = {
      "additional-payments" => Policies::TargetedRetentionIncentivePayments::Award,
      "early-years-payment-provider" => EligibleEyProvider,
      "further-education-payments" => EligibleFeProvider
    }

    def index
      @journey_configurations = Journeys::Configuration.order(created_at: :desc)
    end

    def edit
      @csv_upload = Policies::TargetedRetentionIncentivePayments::AwardCsvImporter.new(admin_user:) if journey_configuration.additional_payments?

      @upload_form = EligibleFeProvidersForm.new(upload_params, admin_user)
      @download_form = EligibleFeProvidersForm.new({}, admin_user)

      @file_upload_history = FileUpload.upload_history(
        FILE_UPLOAD_TARGET_DATA_MODELS[journey_configuration.routing_name]
      )
    end

    def update
      journey_configuration.update!(journey_configuration_params)
      redirect_to admin_journey_configurations_url
    end

    private

    def upload_params
      params.fetch(:eligible_fe_providers_upload, {}).permit(:academic_year)
    end

    def journey_configuration
      return unless params[:id].present?

      @journey_configuration ||= Journeys::Configuration.find(params[:id])
    end

    def journey_configuration_params
      params.require(:journey_configuration).permit(:availability_message, :open_for_submissions, :current_academic_year, :teacher_id_enabled)
    end

    def send_reminders
      return unless journey_configuration.open_for_submissions

      SendReminderEmailsJob.perform_later(journey_configuration.journey)
    end
  end
end
