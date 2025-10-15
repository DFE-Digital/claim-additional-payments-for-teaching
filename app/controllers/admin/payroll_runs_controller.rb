module Admin
  class PayrollRunsController < BaseAdminController
    include Pagy::Backend

    before_action :ensure_service_operator

    def index
      @payroll_runs = PayrollRun
        .includes(:payments, :payment_confirmations)
        .order(created_at: :desc)
    end

    def new
      @claims = Claim
        .includes(:eligibility)
        .payrollable
        .order(submitted_at: :asc)

      @topups = Topup.payrollable
      @total_award_amount = @claims.sum(&:award_amount) + @topups.sum(&:award_amount)
    end

    def create
      claims = Claim.where(id: params[:claim_ids])
      topups = Topup.where(id: params[:topup_ids])

      if claims.empty? && topups.empty?
        redirect_to new_admin_payroll_run_path, alert: "Payroll not run, no claims or top ups"
        return
      end

      payroll_run = PayrollRun.create!(created_by: admin_user)

      PayrollRunJob.perform_later(payroll_run, claims.ids, topups.ids)

      redirect_to [:admin, payroll_run], notice: "Payroll run created"
    rescue ActiveRecord::RecordInvalid => e
      redirect_to new_admin_payroll_run_path, alert: e.message
    end

    def show
      @payroll_run = PayrollRun.find(params[:id])
      @pagy, @payments = pagy(@payroll_run.payments.ordered.includes(:confirmation, claims: [:eligibility]).includes(:topups))
    end

    def destroy
      if PayrollRun.allow_destroy?
        PayrollRun.find(params[:id]).destroy!
        redirect_to admin_payroll_runs_path, notice: "Payroll run deleted"
      else
        redirect_to(
          admin_payroll_runs_path, alert: "Payroll run deletion is not allowed"
        )
      end
    end
  end
end
