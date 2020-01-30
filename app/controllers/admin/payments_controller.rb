module Admin
  class PaymentsController < BaseAdminController
    before_action :ensure_service_operator

    def destroy
      payroll_run = PayrollRun.find(params[:payroll_run_id])
      if payroll_run.confirmation_report_uploaded_by.nil?
        payment = payroll_run.payments.find(params[:id])
        payment.destroy
        redirect_to admin_payroll_run_path(payroll_run), notice: "Payment has been removed from payroll run"
      else
        redirect_to admin_payroll_run_path(payroll_run), alert: "A payment cannot be removed from an already confirmed payroll run"
      end
    end
  end
end
