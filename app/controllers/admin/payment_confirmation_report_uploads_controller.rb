module Admin
  class PaymentConfirmationReportUploadsController < BaseAdminController
    before_action :ensure_service_operator

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
