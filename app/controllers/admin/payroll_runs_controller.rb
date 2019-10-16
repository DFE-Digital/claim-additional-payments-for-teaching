module Admin
  class PayrollRunsController < BaseAdminController
    before_action :ensure_service_operator

    def index
      @payroll_runs = PayrollRun.order(created_at: :desc)
    end

    def new
      @payroll_run = PayrollRun.new(claims: PayrollRun.payrollable_claims)
    end

    def create
      claims = Claim.find(params[:claim_ids])

      payroll_run = PayrollRun.create_with_claims!(claims, created_by: admin_session.user_id)

      redirect_to [:admin, payroll_run]
    end

    def show
      @payroll_run = PayrollRun.find(params[:id])

      respond_to do |format|
        format.html
        format.csv do
          csv = Payroll::ClaimsCsv.new(@payroll_run)
          send_file csv.file, type: "text/csv", filename: csv.filename
        end
      end
    end
  end
end
