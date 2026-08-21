module Admin
  class JourneyConfigurationsController < BaseAdminController
    helper_method :journey_configuration
    before_action :journey_configuration
    before_action :authorise_journey_configuration
    after_action :send_reminders, only: [:update]

    FILE_UPLOAD_TARGET_DATA_MODELS = {
      "targeted-retention-incentive-payments" => Policies::TargetedRetentionIncentivePayments::Award,
      "early-years-payment-provider" => Policies::EarlyYearsPayments::EligibleEyProvider,
      "further-education-payments" => Policies::FurtherEducationPayments::EligibleFeProvider
    }

    def index
      @journey_configurations = Journeys::Configuration.order(created_at: :desc)
    end

    def edit
      load_edit_data
    end

    def update
      @form = Admin::JourneyConfigurationForm.for_journey_configuration(@journey_configuration)
      @form.assign_attributes(journey_configuration_params)

      if @form.save
        flash[:success] = automatic_approvals_flash_message if journey_configuration.saved_change_to_automatic_approvals?
        redirect_to edit_admin_journey_configuration_path(journey_configuration)
      else
        load_edit_data
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def load_edit_data
      @form = Admin::JourneyConfigurationForm.for_journey_configuration(@journey_configuration)

      @awards_upload_form = Policies::TargetedRetentionIncentivePayments::AwardCsvImporter.new(awards_upload_params.merge({admin_user:})) if journey_configuration.targeted_retention_incentive_payments?

      @upload_form = EligibleFeProvidersForm.new(upload_params, admin_user)
      @download_form = EligibleFeProvidersForm.new({}, admin_user)

      @file_upload_history = FileUpload
        .upload_history(
          FILE_UPLOAD_TARGET_DATA_MODELS[journey_configuration.routing_name]
        )
        .includes(:uploaded_by)

      @feature_flags_form = FeatureFlagsForm.new
      @feature_flags_form.load_data

      @flagged_fe_providers_form = FurtherEducationPayments::FlaggedProvidersCsvForm.new(admin: admin_user)
    end

    private

    def authorise_journey_configuration
      authorize :journey_configuration
    end

    def awards_upload_params
      params.fetch(:targeted_retention_incentive_payments_awards_upload, {}).permit(:academic_year, :csv_data)
    end

    def upload_params
      params.fetch(:eligible_fe_providers_upload, {}).permit(:academic_year)
    end

    def journey_configuration
      @journey_configuration ||= Journeys::Configuration.find(params[:id]) if params[:id].present?
    end

    def journey_configuration_params
      permitted = params
        .require(:journey_configuration)
        .permit(
          :availability_message,
          :close_at,
          :open_for_submissions,
          :current_academic_year,
          :teacher_id_enabled,
          :automatic_approvals
        )

      permitted[:close_at] = Time.zone.parse(permitted[:close_at]).in_time_zone("London") if permitted[:close_at].present?

      permitted
    end

    def automatic_approvals_update_requested?
      return false unless params[:journey_configuration].key?(:automatic_approvals)

      ActiveModel::Type::Boolean.new.cast(params[:journey_configuration][:automatic_approvals]) != journey_configuration.automatic_approvals
    end

    def send_reminders
      return unless journey_configuration.open_for_submissions

      SendReminderEmailsJob.perform_later(journey_configuration.journey)
    end

    def automatic_approvals_flash_message
      return unless journey_configuration.saved_change_to_automatic_approvals?

      status = journey_configuration.automatic_approvals ? "on" : "off"
      "Automatic approvals for submitted claims are turned #{status}"
    end
  end
end
