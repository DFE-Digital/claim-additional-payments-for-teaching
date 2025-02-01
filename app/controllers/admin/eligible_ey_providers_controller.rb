module Admin
  class EligibleEyProvidersController < BaseAdminController
    before_action :ensure_service_operator

    helper_method :journey_configuration

    def create
      @upload_form = EligibleEyProvidersForm.new(upload_params, admin_user)

      if @upload_form.invalid?
        render "admin/journey_configurations/edit"
      else
        @upload_form.run_import!
        flash[:notice] = @upload_form.importer.results_message

        redirect_to edit_admin_journey_configuration_path(Journeys::EarlyYearsPayment::Provider::Authenticated::ROUTING_NAME)
      end
    end

    def show
      send_data EligibleEyProvider.csv,
        type: "text/csv",
        filename: "eligible_early_years_providers.csv"
    end

    private

    def journey_configuration
      @journey_configuration ||= Journeys::Configuration.find_by(
        routing_name: Journeys::EarlyYearsPayment::Provider::Authenticated::ROUTING_NAME
      )
    end

    def upload_params
      params.require(:eligible_ey_providers_upload).permit(:file)
    end
  end
end
