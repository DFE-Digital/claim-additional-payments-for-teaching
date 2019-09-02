require "rails_helper"

RSpec.feature "Download CSV of claims" do
  context "User is logged in as a service operator" do
    before do
      stub_dfe_sign_in_with_role(AdminSession::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE)
      visit admin_path
      click_on "Sign in"
    end

    scenario "User downloads a CSV of submitted claims" do
      submitted_claims = create_list(:claim, 5, :submittable, submitted_at: DateTime.now)
      create_list(:claim, 2, :submittable)

      expect(page).to have_link(nil, href: admin_claims_path(format: :csv))
      click_on "Download claims"

      expect(page.response_headers["Content-Type"]).to eq("text/csv")

      csv = CSV.parse(body)
      expect(csv.count).to eq(submitted_claims.count + 1)
    end
  end

  context "User is logged in as a support user" do
    before do
      stub_dfe_sign_in_with_role(AdminSession::SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE)
      visit admin_path
      click_on "Sign in"
    end

    scenario "User cannot download a CSV of submitted claims" do
      expect(page).to_not have_link(nil, href: admin_claims_path(format: :csv))

      visit admin_claims_path(format: :csv)

      expect(page.status_code).to eq(401)
      expect(page).to have_content("Not authorised")
    end
  end

  context "User is not logged in" do
    scenario "User cannot download submitted claims" do
      visit admin_claims_path(format: :csv)

      expect(page).to have_content("Sign in with DfE Sign In")
    end
  end
end
