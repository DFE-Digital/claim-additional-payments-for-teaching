module Admin
  class QualificationReportUploadsController < BaseAdminController
    before_action :ensure_service_operator

    def new
    end

    def create
      @dqt_report_consumer = AutomatedChecks::DQTReportConsumer.new(params[:file], admin_user)
      if @dqt_report_consumer.ingest
        redirect_to admin_claims_path, notice: "DQT data uploaded successfully"
      else
        render :new
      end
    end
  end
end
