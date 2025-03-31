require "rails_helper"

RSpec.feature "Admin performs one login identity task" do
  let(:claim) do
    create(
      :claim,
      :submitted,
      :with_onelogin_idv_data,
      policy: Policies::FurtherEducationPayments,
      onelogin_idv_return_codes: ["A", "B"],
      tasks:
    )
  end

  let(:tasks) do
    [
      create(
        :task,
        name: "one_login_identity",
        passed: false,
        reason: "no_data",
        manual: false,
        created_by: nil
      )
    ]
  end

  context "when user failed One Login IDV" do
    scenario "service operator views task" do
      sign_in_as_service_operator
      claim

      visit admin_claims_path
      click_link claim.reference
      click_link "Confirm the claimant made the claim"

      expect(page).not_to have_content "return code"
    end

    scenario "service admin views task" do
      sign_in_as_service_admin
      claim

      visit admin_claims_path
      click_link claim.reference
      click_link "Confirm the claimant made the claim"

      expect(page).to have_content "return codes: A, B"
    end
  end
end
