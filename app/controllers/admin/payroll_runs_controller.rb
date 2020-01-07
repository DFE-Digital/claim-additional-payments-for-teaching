module Admin
  class PayrollRunsController < BaseAdminController
    before_action :ensure_service_operator

    def index
      @payroll_runs = PayrollRun.order(created_at: :desc)
    end

    def new
      @claims = Claim.payrollable
      @total_award_amount = @claims.sum(&:award_amount)
    end

    def create
      claims = Claim.find(params[:claim_ids])

      payroll_run = PayrollRun.create_with_claims!(claims, created_by: admin_user)

      redirect_to [:admin, payroll_run], notice: "Payroll run created"
    rescue ActiveRecord::RecordInvalid => e
      redirect_to new_admin_payroll_run_path, alert: e.message
    end

    def show
      @payroll_run = PayrollRun.find(params[:id])
    end
  end
end
