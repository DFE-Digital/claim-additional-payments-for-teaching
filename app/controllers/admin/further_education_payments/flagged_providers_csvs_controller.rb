module Admin
  module FurtherEducationPayments
    class FlaggedProvidersCsvsController < Admin::BaseAdminController
      before_action :ensure_service_operator

      def update
        @flagged_fe_providers_form = FlaggedProvidersCsvForm.new(form_params)

        if @flagged_fe_providers_form.save
          flash[:notice] = "Flagged providers CSV uploaded successfully."
        else
          flash[:alert] = @flagged_fe_providers_form.errors.full_messages
        end

        redirect_to edit_admin_journey_configuration_path(
          Journeys::Configuration.find_by!(routing_name: "further-education-payments")
        )
      end

      private

      def form_params
        params
          .require(FlaggedProvidersCsvForm.model_name.param_key)
          .permit(:file)
          .merge(admin: current_admin)
      end
    end
  end
end
