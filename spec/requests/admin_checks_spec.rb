require "rails_helper"

RSpec.describe "Admin checks", type: :request do
  let(:claim) { create(:claim, :submitted) }

  context "when signed in as a service operator" do
    let(:user) { create(:dfe_signin_user) }

    before do
      sign_in_to_admin_with_role(DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE, user.dfe_sign_in_id)
    end

    describe "checks#index" do
      it "shows a list of checks for a claim" do
        get admin_claim_checks_path(claim_id: claim.id)

        expect(response.body).to include(claim.reference)
        expect(response.body).to include("Qualifications")
        expect(response.body).to include("Employment")
      end
    end
  end

  context "when signed in as a payroll operator or a support agent" do
    describe "checks#index" do
      [DfeSignIn::User::SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE, DfeSignIn::User::PAYROLL_OPERATOR_DFE_SIGN_IN_ROLE_CODE].each do |role|
        it "does not allow the claim checks to be viewed" do
          sign_in_to_admin_with_role(role)
          get admin_claim_checks_path(claim_id: claim.id)

          expect(response.code).to eq("401")
        end
      end
    end
  end
end
