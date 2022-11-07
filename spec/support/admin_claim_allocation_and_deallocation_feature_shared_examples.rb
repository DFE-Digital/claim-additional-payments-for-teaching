RSpec.shared_examples "Admin Claim Allocation and Deallocation Feature" do |policy|
  let!(:admin_user) { sign_in_as_service_operator }

  before { create(:policy_configuration, policy.to_s.underscore) }

  context "when viewing an individual claim" do
    let!(:claim) { create(:claim, :submitted, policy: policy) }
    let!(:other_user) { create(:dfe_signin_user, given_name: "Colin", family_name: "Claimhandler", organisation_name: "Department for Education", role_codes: [DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE]) }
    let(:other_user_full_name) { "#{other_user.given_name} #{other_user.family_name}" }
    let(:current_user_full_name) { "#{admin_user.given_name} #{admin_user.family_name}" }

    scenario "a user can assign a claim to themselves and unassign" do
      visit admin_claim_tasks_path(claim)

      expect(page).to have_no_content(current_user_full_name)
      expect(claim.assigned_to).to be_nil
      expect(page).to have_content "This claim is currently unassigned"
      expect(page).to have_link "Assign to yourself"

      click_link "Assign to yourself"

      expect(claim.reload.assigned_to.full_name).to eq(current_user_full_name)
      expect(page).to have_content "You are currently assigned this claim"

      click_on "Back"
      expect(page).to have_content(current_user_full_name)

      visit admin_claim_tasks_path(claim)

      click_link "Unassign"
      expect(claim.reload.assigned_to).to be_nil
      expect(page).to have_content "This claim is currently unassigned"
      expect(page).to have_link "Assign to yourself"
    end

    scenario "user can unallocate a claim" do
      expect(claim.assigned_to).to be_nil
      claim.assigned_to = other_user
      claim.save

      visit admin_claim_tasks_path(claim)

      expect(page).to have_link "Unassign"
      expect(page).to have_content "CAUTION: This claim is currently assigned to #{other_user_full_name}"

      click_link "Unassign"

      expect(claim.reload.assigned_to).to be_nil
      expect(page).to have_content "This claim is currently unassigned"
      expect(page).to have_link "Assign to yourself"
    end

    scenario "user can allocate a claim allocated to another user to themselves" do
      expect(claim.assigned_to).to be_nil
      claim.assigned_to = other_user
      claim.save

      visit admin_claim_tasks_path(claim)

      expect(page).to have_link "Unassign"
      expect(page).to have_content "CAUTION: This claim is currently assigned to #{other_user_full_name}"

      click_link "Unassign"

      expect(claim.reload.assigned_to).to be_nil
      expect(page).to have_content "This claim is currently unassigned"
      expect(page).to have_link "Assign to yourself"

      click_link "Assign to yourself"

      expect(claim.reload.assigned_to.full_name).to eq(current_user_full_name)
      expect(page).to have_content "You are currently assigned this claim"
      expect(page).to have_link "Unassign"
    end
  end
end
