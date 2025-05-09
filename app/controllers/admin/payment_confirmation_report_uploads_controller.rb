module Admin
  class PaymentConfirmationReportUploadsController < BaseAdminController
    before_action :ensure_service_admin

    rate_limit(
      to: 1,
      within: 30.seconds,
      only: :create,
      with: -> do
        redirect_to(
          new_admin_payment_confirmation_report_upload_path,
          alert: "Too many requests"
        )
      end
    )

    def new
      @payroll_run = PayrollRun.find(params[:payroll_run_id])
      @upload_form = PaymentConfirmationReportUploadForm.new(upload_params, @payroll_run, admin_user)
    end

    def create
      @payroll_run = PayrollRun.find(params[:payroll_run_id])
      @upload_form = PaymentConfirmationReportUploadForm.new(upload_params, @payroll_run, admin_user)

      @upload_form.run_import!

      if @upload_form.invalid?
        render :new
      else
        redirect_to admin_payroll_runs_path, notice: t(".success", counter: "#{@upload_form.importer.updated_payment_ids.count} #{"payment".pluralize(@upload_form.importer.updated_payment_ids.count)}")
      end
    end

    private

    def upload_params
      params.fetch(:payment_confirmation_report_upload, {}).permit(:file)
    end
  end
end
