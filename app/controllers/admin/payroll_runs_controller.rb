module Admin
  class PayrollRunsController < BaseAdminController
    include Pagy::Backend

    before_action :ensure_service_operator

    def index
      @payroll_runs = PayrollRun.order(created_at: :desc)
    end

    def new
      @claims = Claim.payrollable.order(submitted_at: :asc)

      # Due to limitations with the current payroll software we need a temporary
      # cap on the number of claims that can enter payroll, especially expecting
      # a high volume of approved claims in the first few months.
      #
      # Ideally, we should limit topups as well, as some may be related to claims
      # paid in a previous payroll run, but we wouldn't have any topups at the beginning.
      #
      # TODO: Remove this capping once the payroll software is upgraded.
      if @claims.size > PayrollRun::MAX_MONTHLY_PAYMENTS
        flash[:notice] = "The number of payments entering this payrun will be capped to #{PayrollRun::MAX_MONTHLY_PAYMENTS}"
        @claims = @claims.limit(PayrollRun::MAX_MONTHLY_PAYMENTS)
      end

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
      @pagy, @payments = pagy(@payroll_run.payments.ordered.includes(claims: [:eligibility]).includes(:topups))
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
