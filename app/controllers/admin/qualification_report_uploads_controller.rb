module Admin
  class QualificationReportUploadsController < BaseAdminController
    include ActionView::Helpers::TextHelper

    before_action :ensure_service_operator

    def new
    end

    def create
      @dqt_report_consumer = AutomatedChecks::DqtReportConsumer.new(params[:file], admin_user)

      if @dqt_report_consumer.errors.any?
        render :new
      else
        @dqt_report_consumer.ingest
        redirect_to admin_claims_path, notice: "DQT report uploaded successfully. Automatically completed #{pluralize(@dqt_report_consumer.completed_tasks, "task")} for #{pluralize(@dqt_report_consumer.total_claims_checked, "checked claim")}."
      end
    rescue ActiveRecord::RecordInvalid
      redirect_to new_admin_qualification_report_upload_path, alert: "There was a problem, please try again"
    end
  end
end
