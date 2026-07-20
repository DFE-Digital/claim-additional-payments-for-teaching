module Admin
  class EligibleEytfiProvidersController < BaseAdminController
    before_action :ensure_service_operator

    helper_method :journey_configuration

    rate_limit(
      to: 1,
      within: 30.seconds,
      only: :create,
      with: -> do
        redirect_to(
          edit_admin_journey_configuration_path(
            Journeys::FurtherEducationPayments.routing_name
          ),
          alert: "Too many requests"
        )
      end
    )

    def show
      upload = FileUpload.latest_version_for(
        Policies::EarlyYearsTeachersFinancialIncentivePayments::EligibleEytfiProvider,
        AcademicYear.current
      ).order(created_at: :desc).first

      upload_date = upload.created_at.to_date.iso8601

      send_data(
        upload.body,
        type: "text/csv",
        filename: "eytrp_nurseries-#{upload_date}.csv"
      )
    end

    def create
      @upload_form = EligibleEytfiProvidersForm.new(upload_params, admin_user)

      if @upload_form.valid? && @upload_form.save
        redirect_to admin_file_upload_path(@upload_form.file_upload)
      else
        render "admin/journey_configurations/edit"
      end
    end

    private

    def journey_configuration
      @journey_configuration ||= Journeys::Configuration.find_by(
        routing_name: Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name
      )
    end

    def upload_params
      params.require(:eligible_eytfi_providers_upload).permit(:academic_year, :file)
    end
  end
end
