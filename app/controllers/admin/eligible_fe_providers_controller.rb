module Admin
  class EligibleFeProvidersController < BaseAdminController
    before_action :ensure_service_operator

    helper_method :journey_configuration

    rate_limit(
      to: 1,
      within: 30.seconds,
      only: :create,
      with: -> do
        redirect_to(
          edit_admin_journey_configuration_path(
            Journeys::FurtherEducationPayments::ROUTING_NAME
          ),
          alert: "Too many requests"
        )
      end
    )

    def create
      @download_form = EligibleFeProvidersForm.new({}, admin_user)
      @upload_form = EligibleFeProvidersForm.new(upload_params, admin_user)

      if @upload_form.invalid?
        render "admin/journey_configurations/edit"
      else
        @upload_form.run_import!
        flash[:notice] = @upload_form.importer.results_message

        redirect_to edit_admin_journey_configuration_path(Journeys::FurtherEducationPayments::ROUTING_NAME, eligible_fe_providers_upload: {academic_year: @upload_form.academic_year})
      end
    end

    def show
      @download_form = EligibleFeProvidersForm.new(download_params, admin_user)

      send_data Policies::FurtherEducationPayments::EligibleFeProvider.csv_for_academic_year(@download_form.academic_year),
        type: "text/csv",
        filename: "eligible_further_education_providers_#{@download_form.academic_year}.csv"
    end

    private

    def journey_configuration
      @journey_configuration ||= Journeys::Configuration.find_by(
        routing_name: Journeys::FurtherEducationPayments::ROUTING_NAME
      )
    end

    def upload_params
      params.require(:eligible_fe_providers_upload).permit(:academic_year, :file)
    end

    def download_params
      params.require(:eligible_fe_providers_download).permit(:academic_year)
    end
  end
end
