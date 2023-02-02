module Admin
  class PayrollRunsController < BaseAdminController
    before_action :ensure_service_operator

    def index
      @payroll_runs = PayrollRun.order(created_at: :desc)
    end

    def new
      @claims = Claim.payrollable
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

      payroll_run = PayrollRun.create_with_claims!(claims, topups, created_by: admin_user)

      redirect_to [:admin, payroll_run], notice: "Payroll run created"
    rescue ActiveRecord::RecordInvalid => e
      redirect_to new_admin_payroll_run_path, alert: e.message
    end

    # NOTE: Optimisation - preload payments, claims and eligibility
    def show
      @payroll_run = PayrollRun.where(id: params[:id]).includes({claims: [:eligibility]}, {payments: [{claims: [:eligibility]}]}).first
    end
  end
end
