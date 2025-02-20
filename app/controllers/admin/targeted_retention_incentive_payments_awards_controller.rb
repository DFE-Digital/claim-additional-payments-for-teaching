module Admin
  class TargetedRetentionIncentivePaymentsAwardsController < BaseAdminController
    helper_method :journey_configuration

    def index
      send_data Policies::TargetedRetentionIncentivePayments::Award.csv_for_academic_year(academic_year), type: "text/csv", filename: "awards_#{academic_year}.csv"
    end

    def create
      @csv_upload = Policies::TargetedRetentionIncentivePayments::AwardCsvImporter.new(
        **upload_params
        .to_h
        .merge(admin_user:)
        .symbolize_keys
      )

      if @csv_upload.process
        flash[:notice] = "Award amounts for #{@csv_upload.academic_year} successfully updated."
        return redirect_to edit_admin_journey_configuration_path(journey_configuration)
      end

      @file_upload_history = FileUpload.upload_history(Policies::TargetedRetentionIncentivePayments::Award)

      render "admin/journey_configurations/edit"
    end

    private

    def upload_params
      params.require(:policies_targeted_retention_incentive_payments_award_csv_importer).permit(:academic_year, :csv_data)
    end

    def academic_year
      AcademicYear.new(params.require(:policies_targeted_retention_incentive_payments_award).require(:academic_year))
    end

    # This one will be tricky
    def journey_configuration
      @journey_configuration ||= Journeys.for_policy(Policies::TargetedRetentionIncentivePayments).configuration
    end
  end
end
