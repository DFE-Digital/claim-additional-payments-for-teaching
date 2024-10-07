module Admin
  class ReportsController < BaseAdminController
    before_action :ensure_service_operator

    def index
      @reports = Report.order(created_at: :desc)
    end

    def show
      respond_to do |format|
        format.csv {
          report = Report.find(params[:id])
          send_data report.csv, filename: "#{report.name.parameterize(separator: "_")}_#{report.created_at.iso8601}.csv"
        }
      end
    end
  end
end
