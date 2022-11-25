module Admin
  class LevellingUpPremiumPaymentsAwardsController < BaseAdminController
    def index
      response.headers["Content-Type"] = "text/csv"
      response.headers["Content-Disposition"] = "attachment; filename=awards_#{academic_year}.csv"

      send_data LevellingUpPremiumPayments::Award.csv_for_academic_year(academic_year), filename: "awards_#{academic_year}.csv"
    end

    private

    def academic_year
      AcademicYear.new(params[:academic_year])
    end
  end
end
