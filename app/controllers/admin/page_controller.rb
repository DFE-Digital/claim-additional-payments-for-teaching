module Admin
  class PageController < BaseAdminController
    before_action :ensure_service_operator

    def index
      flash.now[:notice] = "There is currently no School Workforce Census data present" if SchoolWorkforceCensus.all.size.zero?

      @dashboard = Dashboard.new(academic_year: selected_academic_year)
    end

    private

    def selected_academic_year
      @selected_academic_year ||= if params[:academic_year].blank?
        AcademicYear.current
      else
        AcademicYear.new(params[:academic_year])
      end
    end
  end
end
