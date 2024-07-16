module Admin
  class EligibleFeProvidersController < BaseAdminController
    before_action :ensure_service_operator

    helper_method :journey_configuration

    def create
      @download_form = EligibleFeProvidersForm.new
      @upload_form = EligibleFeProvidersForm.new(upload_params)

      if @upload_form.invalid?
        render "admin/journey_configurations/edit"
      else
        @upload_form.importer.run
        flash[:notice] = @upload_form.importer.results_message

        redirect_to edit_admin_journey_configuration_path(Journeys::FurtherEducationPayments::ROUTING_NAME)
      end
    end

    def show
      @download_form = EligibleFeProvidersForm.new(download_params)

      send_data EligibleFeProvider.csv_for_academic_year(@download_form.academic_year),
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
      params.require(:eligible_fe_providers).permit(:academic_year, :file)
    end

    def download_params
      params.require(:eligible_fe_providers).permit(:academic_year)
    end
  end
end
