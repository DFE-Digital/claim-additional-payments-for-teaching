module Admin
  class LevellingUpPremiumPaymentsAwardsController < BaseAdminController
    helper_method :policy_configuration

    def index
      response.headers["Content-Type"] = "text/csv"
      response.headers["Content-Disposition"] = "attachment; filename=awards_#{academic_year}.csv"

      send_data LevellingUpPremiumPayments::Award.csv_for_academic_year(academic_year), filename: "awards_#{academic_year}.csv"
    end

    def create
      @csv_upload = LevellingUpPremiumPayments::AwardCsvImporter.new(**upload_params.to_h.symbolize_keys)

      if @csv_upload.process
        flash[:notice] = "Award amounts for #{policy_configuration.current_academic_year} successfully updated."
        return redirect_to edit_admin_policy_configuration_path(policy_configuration)
      end

      render "admin/policy_configurations/edit"
    end

    private

    def upload_params
      params.require(:levelling_up_premium_payments_award_csv_importer).permit(:academic_year, :csv_data)
    end

    def academic_year
      AcademicYear.new(params.require(:levelling_up_premium_payments_award).require(:academic_year))
    end

    def policy_configuration
      @policy_configuration ||= PolicyConfiguration.for(LevellingUpPremiumPayments)
    end
  end
end
