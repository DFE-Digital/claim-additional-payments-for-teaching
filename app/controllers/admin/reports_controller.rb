module Admin
  class ReportsController < BaseAdminController
    before_action :ensure_service_operator

    def index
    end

    def show
      respond_to do |format|
        format.csv do
          send_data(report.to_csv, filename: report.filename)
        end
      end
    end

    private

    def report
      @report ||= case params[:name]
      when "fe-approved-claims-with-failing-provider-verification"
        Reports::FeApprovedClaimsWithFailingProviderVerification.new
      else
        raise ActiveRecord::RecordNotFound
      end
    end
  end
end
