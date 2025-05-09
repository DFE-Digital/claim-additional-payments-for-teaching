module Admin
  class QualificationReportUploadsController < BaseAdminController
    include ActionView::Helpers::TextHelper

    before_action :ensure_service_operator

    rate_limit(
      to: 1,
      within: 30.seconds,
      only: :create,
      with: -> do
        redirect_to(
          new_admin_qualification_report_upload_path,
          alert: "Too many requests"
        )
      end
    )

    def new
      @upload_form = QualificationReportForm.new(upload_params, admin_user)
    end

    def create
      @upload_form = QualificationReportForm.new(upload_params, admin_user)

      if @upload_form.invalid?
        render :new
      else
        @upload_form.run_import!
        flash[:notice] = "DQT report uploaded successfully. Automatically completed #{pluralize(@upload_form.importer.completed_tasks, "task")} for #{pluralize(@upload_form.importer.total_claims_checked, "checked claim")}."

        redirect_to admin_claims_path
      end
    end

    private

    def upload_params
      params.fetch(:qualification_report_upload, {}).permit(:file)
    end
  end
end
