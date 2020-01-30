require "rails_helper"

RSpec.describe "Admin payroll run payments" do
  let(:admin) { create(:dfe_signin_user) }

  before do
    sign_in_to_admin_with_role(DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE, admin.dfe_sign_in_id)
  end

  describe "destroy" do
    let(:payroll_run) { create(:payroll_run, claims_counts: {MathsAndPhysics => 1, StudentLoans => 1}) }
    let(:payment) { payroll_run.payments.first }

    it "deletes a payroll run and redirects with a message" do
      expect {
        delete admin_payroll_run_payment_path(
          payroll_run_id: payroll_run.id,
          id: payment.id
        )
      }.to change(payroll_run.reload.payments, :count).by(-1)

      expect(payroll_run.payments).to_not include(payment)

      expect(response).to redirect_to(admin_payroll_run_path(payroll_run))
      follow_redirect!

      expect(response.body).to include("Payment has been removed from payroll run")
    end

    it "cannot delete a payment from an already confirmed payroll run" do
      payroll_run.confirmation_report_uploaded_by = admin.id
      payroll_run.save

      expect {
        delete admin_payroll_run_payment_path(
          payroll_run_id: payroll_run.id,
          id: payment.id
        )
      }.to change(payroll_run.reload.payments, :count).by(0)

      expect(payroll_run.payments).to include(payment)

      expect(response).to redirect_to(admin_payroll_run_path(payroll_run))
      follow_redirect!

      expect(response.body).to include("A payment cannot be removed from an already confirmed payroll run")
    end
  end
end
