module Admin
  class EligibleEyProvidersController < BaseAdminController
    before_action :ensure_service_operator

    helper_method :journey_configuration

    def create
      @download_form = EligibleEyProvidersForm.new
      @upload_form = EligibleEyProvidersForm.new(upload_params)

      if @upload_form.invalid?
        render "admin/journey_configurations/edit"
      else
        @upload_form.importer.run
        flash[:notice] = @upload_form.importer.results_message

        redirect_to edit_admin_journey_configuration_path(Journeys::EarlyYearsPayment::Provider::ROUTING_NAME, eligible_ey_providers_upload: {academic_year: @upload_form.academic_year})
      end
    end

    def show
      @download_form = EligibleEyProvidersForm.new(download_params)

      send_data EligibleEyProvider.csv_for_academic_year(@download_form.academic_year),
        type: "text/csv",
        filename: "eligible_early_years_providers_#{@download_form.academic_year}.csv"
    end

    private

    def journey_configuration
      @journey_configuration ||= Journeys::Configuration.find_by(
        routing_name: Journeys::EarlyYearsPayment::Provider::ROUTING_NAME
      )
    end

    def upload_params
      params.require(:eligible_ey_providers_upload).permit(:academic_year, :file)
    end

    def download_params
      params.require(:eligible_ey_providers_download).permit(:academic_year)
    end
  end
end
