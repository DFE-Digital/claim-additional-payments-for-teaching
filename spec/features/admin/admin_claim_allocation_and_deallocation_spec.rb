require "rails_helper"

RSpec.feature "Admin claim allocation and deallocation" do
  let!(:admin_user) { sign_in_as_service_operator }

  context "when viewing an individual claim" do
    let!(:claim) { create(:claim, :submitted, assigned_to: other_user) }
    let!(:other_user) { create(:dfe_signin_user, given_name: "Colin", family_name: "Claimhandler", organisation_name: "Department for Education", role_codes: [DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE]) }
    let(:other_user_full_name) { "#{other_user.given_name} #{other_user.family_name}" }
    let(:current_user_full_name) { "#{admin_user.given_name} #{admin_user.family_name}" }

    scenario "user can assign and unassign a claim" do
      visit admin_claim_tasks_path(claim)
      expect(page).to have_content "CAUTION: This claim is currently assigned to #{other_user_full_name}"
      click_link "Unassign"

      expect(page).to have_content "This claim is currently unassigned"
      click_link "Assign to yourself"

      expect(page).to have_content "You are currently assigned this claim"
      click_on "Back"

      expect(page).to have_content(current_user_full_name)

      visit admin_claim_tasks_path(claim)
      click_link "Unassign"

      expect(page).to have_content "This claim is currently unassigned"
      expect(page).to have_link "Assign to yourself"
    end
  end
end
