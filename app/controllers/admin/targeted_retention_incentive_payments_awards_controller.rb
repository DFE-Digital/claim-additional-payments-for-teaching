module Admin
  class TargetedRetentionIncentivePaymentsAwardsController < BaseAdminController
    helper_method :journey_configuration

    def index
      send_data Policies::TargetedRetentionIncentivePayments::Award.csv_for_academic_year(academic_year), type: "text/csv", filename: "awards_#{academic_year}.csv"
    end

    def create
      @awards_upload_form = Policies::TargetedRetentionIncentivePayments::AwardCsvImporter.new(awards_upload_params.merge({admin_user:})) if journey_configuration.additional_payments?

      if @awards_upload_form.process
        flash[:notice] = "Award amounts for #{@awards_upload_form.academic_year} successfully updated."
        return redirect_to edit_admin_journey_configuration_path(journey_configuration)
      end

      @file_upload_history = FileUpload.upload_history(Policies::TargetedRetentionIncentivePayments::Award)

      render "admin/journey_configurations/edit"
    end

    private

    def awards_upload_params
      params.fetch(:targeted_retention_incentive_payments_awards_upload, {}).permit(:academic_year, :csv_data)
    end

    def academic_year
      AcademicYear.new(params.require(:policies_targeted_retention_incentive_payments_award).require(:academic_year))
    end

    def journey_configuration
      @journey_configuration ||= Journeys.for_policy(Policies::TargetedRetentionIncentivePayments).configuration
    end
  end
end
