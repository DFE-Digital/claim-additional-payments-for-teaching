require "rails_helper"

RSpec.describe "Admin page" do
  context "when signed in as a payroll operator" do
    it "returns a unauthorized response" do
      sign_in_to_admin_with_role(DfeSignIn::User::PAYROLL_OPERATOR_DFE_SIGN_IN_ROLE_CODE)

      get admin_root_path

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
