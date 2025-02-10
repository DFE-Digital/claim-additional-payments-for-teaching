module Admin
  class LevellingUpPremiumPaymentsAwardsController < BaseAdminController
    helper_method :journey_configuration

    def index
      send_data Policies::LevellingUpPremiumPayments::Award.csv_for_academic_year(academic_year), type: "text/csv", filename: "awards_#{academic_year}.csv"
    end

    def create
      @csv_upload = Policies::LevellingUpPremiumPayments::AwardCsvImporter.new(**upload_params.to_h.symbolize_keys)

      if @csv_upload.process
        flash[:notice] = "Award amounts for #{@csv_upload.academic_year} successfully updated."
        return redirect_to edit_admin_journey_configuration_path(journey_configuration)
      end

      render "admin/journey_configurations/edit"
    end

    private

    def upload_params
      params.require(:policies_levelling_up_premium_payments_award_csv_importer).permit(:academic_year, :csv_data)
    end

    def academic_year
      AcademicYear.new(params.require(:policies_levelling_up_premium_payments_award).require(:academic_year))
    end

    def journey_configuration
      @journey_configuration ||= Journeys.for_policy(Policies::LevellingUpPremiumPayments).configuration
    end
  end
end
