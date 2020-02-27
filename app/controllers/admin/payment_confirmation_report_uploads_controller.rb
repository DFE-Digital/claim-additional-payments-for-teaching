module Admin
  class PaymentConfirmationReportUploadsController < BaseAdminController
    before_action :ensure_service_operator

    def new
      @payroll_run = PayrollRun.find(params[:payroll_run_id])
    end

    def create
      @payroll_run = PayrollRun.find(params[:payroll_run_id])
      @payment_confirmation = PaymentConfirmation.new(@payroll_run, params[:file], admin_user)
      if @payment_confirmation.ingest
        redirect_to admin_payroll_runs_path, notice: "Payment Confirmation Report successfully uploaded"
      else
        render :new
      end
    end
  end
end
