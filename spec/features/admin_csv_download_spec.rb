require "rails_helper"

RSpec.feature "Download CSV of claims" do
  context "User is logged in" do
    before do
      stub_dfe_sign_in_with_role(AdminSession::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE)
      visit admin_path
      click_on "Sign in"
    end

    scenario "User downloads a CSV" do
      submitted_claims = create_list(:claim, 5, :submittable, submitted_at: DateTime.now)
      create_list(:claim, 2, :submittable)

      click_on "Download claims"

      expect(page.response_headers["Content-Type"]).to eq("text/csv")

      csv = CSV.parse(body)
      expect(csv.count).to eq(submitted_claims.count + 1)
    end
  end

  context "User is not logged in" do
    scenario "User cannot download claims" do
      visit admin_claims_path(format: :csv)

      expect(page).to have_content("Sign in with DfE Sign In")
    end
  end
end
