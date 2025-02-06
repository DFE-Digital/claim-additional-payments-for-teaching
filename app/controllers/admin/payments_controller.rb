module Admin
  class PaymentsController < BaseAdminController
    before_action :ensure_service_operator
    before_action :find_payroll_run, except: [:index, :show]
    before_action :find_payment, except: [:index, :show]

    def index
      @claim = Claim.find(params[:claim_id])
    end

    def show
      @payment = Payment.includes(
        non_topup_claims: :eligibility,
        topups: [:created_by, {claim: :eligibility}]
      ).find(params[:id])
    end

    def remove
      @claims = @payment.claims
    end

    def destroy
      if @payment.confirmed?
        redirect_to admin_payroll_run_path(@payroll_run), alert: "A payment cannot be removed once confirmed"
      else
        @claims = @payment.claims.to_a
        @payment.destroy
      end
    end

    private

    def find_payroll_run
      @payroll_run = PayrollRun.find(params[:payroll_run_id])
    end

    def find_payment
      @payment = @payroll_run.payments.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_payroll_run_path(@payroll_run), alert: "This payment cannot be found in the payroll run. Maybe you already deleted it?"
    end
  end
end
