module Admin
  class PaymentConfirmationReportUploadsController < BaseAdminController
    before_action :ensure_service_operator

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
    end

    def create
      @payroll_run = PayrollRun.find(params[:payroll_run_id])
      @payment_confirmation = PaymentConfirmationUpload.new(@payroll_run, params[:file], admin_user)
      if @payment_confirmation.ingest
        redirect_to admin_payroll_runs_path, notice: t(".success", counter: "#{@payment_confirmation.updated_payment_ids.count} #{"payment".pluralize(@payment_confirmation.updated_payment_ids.count)}")
      else
        render :new
      end
    end
  end
end
