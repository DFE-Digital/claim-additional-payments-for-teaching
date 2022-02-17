require "rails_helper"

RSpec.feature "Admin Claim assignment" do
  before do
    submitted_claims = []
    @signed_in_user = sign_in_as_service_operator
    submitted_claims << create_list(:claim, 2, :submitted, policy: StudentLoans)
    submitted_claims << create_list(:claim, 13, :submitted, policy: EarlyCareerPayments)
    submitted_claims << create_list(:claim, 4, :submitted, policy: StudentLoans)
    submitted_claims << create_list(:claim, 1, :submitted, policy: EarlyCareerPayments)
    submitted_claims << create_list(:claim, 3, :submitted, policy: StudentLoans)
    submitted_claims << create_list(:claim, 12, :submitted, policy: EarlyCareerPayments)
    @submitted_claims = submitted_claims.flatten
  end

  after do
    Claim.awaiting_decision.update_all(assigned_to_id: nil)
  end

  let(:first_claim) { @submitted_claims[0] }
  let(:twenty_fifth_claim) { @submitted_claims[24] }
  let(:twenty_sixth_claim) { @submitted_claims[25] }
  let(:thirtieth_claim) { @submitted_claims[29] }
  let(:thirty_fifth_claim) { @submitted_claims[34] }
  let!(:sarah) { create(:dfe_signin_user, given_name: "Sarah", family_name: "Strawbridge", organisation_name: "Department for Education", role_codes: [DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE]) }
  let!(:frank) { create(:dfe_signin_user, given_name: "Frank", family_name: "Yee", organisation_name: "Department for Education", role_codes: [DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE]) }
  let!(:abdul) { create(:dfe_signin_user, given_name: "Abdul", family_name: "Rafiq", organisation_name: "Department for Education", role_codes: [DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE]) }
  let!(:tripti) { create(:dfe_signin_user, given_name: "Tripti", family_name: "Kumar", organisation_name: "Cantium Business Services", role_codes: [DfeSignIn::User::PAYROLL_OPERATOR_DFE_SIGN_IN_ROLE_CODE]) }

  context "when viewing claims awaiting a decision" do
    scenario "with more than 25 claims to be allocated" do
      click_on "View claims"

      expect(page).to have_select("allocate_to", options: ["Jo Bloggs", "Sarah Strawbridge", "Frank Yee", "Abdul Rafiq"])
      expect(page).to have_button("Allocate 25 claims", disabled: false)
      expect(page).to have_button("Unallocate claims")
      expect(@submitted_claims.size).to eq 35

      [first_claim, twenty_fifth_claim, twenty_sixth_claim, thirtieth_claim, thirty_fifth_claim].each do |claim|
        expect(claim.assigned_to).to be_nil
      end

      select "Frank Yee", from: "allocate_to"
      click_on "Allocate 25 claims"

      within(".govuk-flash__notice") do
        expect(page).to have_text I18n.t("admin.allocations.bulk_allocate.success", quantity: 25, dfe_user: frank.full_name)
      end

      [first_claim, twenty_fifth_claim].each do |claim|
        expect(claim.reload.assigned_to.full_name).to eq "Frank Yee"
      end
      [twenty_sixth_claim, thirtieth_claim, thirty_fifth_claim].each do |claim|
        expect(claim.reload.assigned_to).to be_nil
      end

      expect(page).to have_button("Allocate 10 claims")
      click_on "Allocate"

      within(".govuk-flash__notice") do
        expect(page).to have_text I18n.t("admin.allocations.bulk_allocate.success", quantity: 10, dfe_user: @signed_in_user.full_name)
      end

      [first_claim, twenty_fifth_claim].each do |claim|
        expect(claim.reload.assigned_to.full_name).to eq "Frank Yee"
      end
      [twenty_sixth_claim, thirtieth_claim, thirty_fifth_claim].each do |claim|
        expect(claim.reload.assigned_to.full_name).to eq "Jo Bloggs"
      end

      expect(page).to have_button "Allocate claims", disabled: true
    end

    scenario "with all claims allocated" do
      Claim.awaiting_decision.update_all(assigned_to_id: abdul.id)

      click_on "View claims"

      @submitted_claims.each do |claim|
        expect(claim.reload.assigned_to.full_name).to eq "Abdul Rafiq"
      end

      expect(page).to have_button "Allocate claims", disabled: true

      select "Abdul Rafiq", from: "allocate_to"
      click_on "Unallocate"

      within(".govuk-flash__notice") do
        expect(page).to have_text I18n.t("admin.allocations.bulk_deallocate.success", quantity: 25, dfe_user: abdul.full_name)
      end

      @submitted_claims.each do |claim|
        expect(claim.reload.assigned_to).to be_nil
      end

      expect(page).to have_button "Allocate 25 claims", disabled: false
    end
  end

  context "when viewing an individual claim" do
    let!(:claim) { create(:claim, :submitted, policy: EarlyCareerPayments) }

    scenario "user can allocate an unallocated claim to themselves" do
      visit admin_claim_tasks_path(claim)

      expect(claim.assigned_to).to be_nil
      expect(page).to have_content "This claim is currently unassigned"
      expect(page).to have_link "Assign to yourself"

      click_link "Assign to yourself"

      expect(claim.reload.assigned_to.full_name).to eq "Jo Bloggs"
      expect(page).to have_content "You are currently assigned this claim"
      expect(page).to have_link "Unassign"
    end

    scenario "user can unallocate a claim" do
      expect(claim.assigned_to).to be_nil
      claim.assigned_to = sarah
      claim.save

      visit admin_claim_tasks_path(claim)

      expect(page).to have_link "Unassign"
      expect(page).to have_content "CAUTION: This claim is currently assigned to Sarah Strawbridge"

      click_link "Unassign"

      expect(claim.reload.assigned_to).to be_nil
      expect(page).to have_content "This claim is currently unassigned"
      expect(page).to have_link "Assign to yourself"
    end

    scenario "user can allocate a claim allocated to another user to themselves" do
      expect(claim.assigned_to).to be_nil
      claim.assigned_to = sarah
      claim.save

      visit admin_claim_tasks_path(claim)

      expect(page).to have_link "Unassign"
      expect(page).to have_content "CAUTION: This claim is currently assigned to Sarah Strawbridge"

      click_link "Unassign"

      expect(claim.reload.assigned_to).to be_nil
      expect(page).to have_content "This claim is currently unassigned"
      expect(page).to have_link "Assign to yourself"

      click_link "Assign to yourself"

      expect(claim.reload.assigned_to.full_name).to eq "Jo Bloggs"
      expect(page).to have_content "You are currently assigned this claim"
      expect(page).to have_link "Unassign"
    end
  end
end
