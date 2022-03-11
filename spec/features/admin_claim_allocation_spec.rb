require "rails_helper"

RSpec.feature "Claims awaiting a decision" do
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

  # StudentLoans
  let(:first_claim) { @submitted_claims[0] }
  let(:second_claim) { @submitted_claims[1] }

  let(:sixteenth_claim) { @submitted_claims[15] }
  let(:seventeenth_claim) { @submitted_claims[16] }
  let(:eighteenth_claim) { @submitted_claims[17] }
  let(:nineteenth_claim) { @submitted_claims[18] }

  let(:twenty_first_claim) { @submitted_claims[20] }
  let(:twenty_second_claim) { @submitted_claims[21] }
  let(:twenty_third_claim) { @submitted_claims[22] }

  # EarlyCareerPayments
  let(:third_claim) { @submitted_claims[2] }
  let(:fifteenth_claim) { @submitted_claims[14] }

  let(:twentieth_claim) { @submitted_claims[19] }

  let(:twenty_fourth_claim) { @submitted_claims[23] }
  let(:twenty_fifth_claim) { @submitted_claims[24] }
  let(:twenty_sixth_claim) { @submitted_claims[25] }
  let(:thirtieth_claim) { @submitted_claims[29] }
  let(:thirty_fifth_claim) { @submitted_claims[34] }

  let(:student_loan_claims) do
    [
      first_claim,
      second_claim,
      sixteenth_claim,
      seventeenth_claim,
      eighteenth_claim,
      nineteenth_claim,
      twenty_first_claim,
      twenty_second_claim,
      twenty_third_claim
    ]
  end

  let(:early_career_payment_claims) do
    [
      @submitted_claims.slice(3...14),
      twentieth_claim,
      @submitted_claims.slice(24...35)
    ].flatten
  end

  let!(:sarah) { create(:dfe_signin_user, given_name: "Sarah", family_name: "Strawbridge", organisation_name: "Department for Education", role_codes: [DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE]) }
  let!(:frank) { create(:dfe_signin_user, given_name: "Frank", family_name: "Yee", organisation_name: "Department for Education", role_codes: [DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE]) }
  let!(:abdul) { create(:dfe_signin_user, given_name: "Abdul", family_name: "Rafiq", organisation_name: "Department for Education", role_codes: [DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE]) }
  let!(:tripti) { create(:dfe_signin_user, given_name: "Tripti", family_name: "Kumar", organisation_name: "Cantium Business Services", role_codes: [DfeSignIn::User::PAYROLL_OPERATOR_DFE_SIGN_IN_ROLE_CODE]) }

  context "with more than 25 claims" do
    scenario "assign first 25 to one Claim's checker" do
      click_on "View claims"

      within("#allocations") do
        expect(page).to have_select("allocate_to_team_member", options: ["Jo Bloggs", "Sarah Strawbridge", "Frank Yee", "Abdul Rafiq"])
        expect(page).to have_select("allocate_to_policy", options: ["All", "Student Loans", "Maths and Physics", "Early-Career Payments"])
        expect(page).to have_button("Allocate claims", disabled: false)
        expect(page).to have_button("Unallocate claims")
      end
      expect(@submitted_claims.size).to eq 35

      @submitted_claims.each do |claim|
        expect(claim.assigned_to).to be_nil
      end
      [first_claim, twenty_fifth_claim, twenty_sixth_claim, thirtieth_claim, thirty_fifth_claim].each do |claim|
        expect(claim.assigned_to).to be_nil
      end

      select "Frank Yee", from: "allocate_to_team_member"
      select "All", from: "allocate_to_policy"
      click_on "Allocate claims"

      within(".govuk-flash__notice") do
        expect(page).to have_text I18n.t(
          "admin.allocations.bulk_allocate.success",
          quantity: 25,
          pluralized_or_singular_claim: "claims",
          allocate_to_policy: "",
          dfe_user: frank.full_name.titleize
        ).squeeze(" ")
      end

      [first_claim, twenty_fifth_claim].each do |claim|
        expect(claim.reload.assigned_to.full_name).to eq "Frank Yee"
      end
      [twenty_sixth_claim, thirtieth_claim, thirty_fifth_claim].each do |claim|
        expect(claim.reload.assigned_to).to be_nil
      end

      expect(page).to have_button "Allocate claims", disabled: false
    end

    scenario "assign outstanding 10 claims when 25 already allocated" do
      @submitted_claims.slice(0..24).each do |claim|
        claim.assigned_to = @signed_in_user
        claim.save

        expect(claim.reload.assigned_to.full_name).to eq "Jo Bloggs"
      end

      click_on "View claims"

      select "Frank Yee", from: "allocate_to_team_member"
      select "All", from: "allocate_to_policy"

      click_on "Allocate"

      within(".govuk-flash__notice") do
        expect(page).to have_text I18n.t(
          "admin.allocations.bulk_allocate.success",
          quantity: 10,
          pluralized_or_singular_claim: "claims",
          allocate_to_policy: "",
          dfe_user: frank.full_name.titleize
        ).squeeze(" ")
      end

      @submitted_claims.slice(25, 36).each do |claim|
        expect(claim.reload.assigned_to.full_name).to eq "Frank Yee"
      end

      expect(page).to have_button "Allocate claims", disabled: true
    end
  end

  context "when assigning by policy" do
    scenario "Student Loans" do
      click_on "View claims"

      expect(@submitted_claims.size).to eq 35

      within("#allocations") do
        expect(page).to have_select("allocate_to_team_member", options: ["Jo Bloggs", "Sarah Strawbridge", "Frank Yee", "Abdul Rafiq"])
        expect(page).to have_select("allocate_to_policy", options: ["All", "Student Loans", "Maths and Physics", "Early-Career Payments"])
        expect(page).to have_button("Allocate claims", disabled: false)
        expect(page).to have_button("Unallocate claims")
      end

      @submitted_claims.each do |claim|
        expect(claim.assigned_to).to be_nil
      end

      select "Frank Yee", from: "allocate_to_team_member"
      select "Student Loans", from: "allocate_to_policy"
      click_on "Allocate claims"

      within(".govuk-flash__notice") do
        expect(page).to have_text I18n.t(
          "admin.allocations.bulk_allocate.success",
          quantity: 9,
          pluralized_or_singular_claim: "claims",
          allocate_to_policy: "Student Loans",
          dfe_user: frank.full_name.titleize
        ).squeeze(" ")
      end

      [first_claim, second_claim].each do |claim|
        expect(claim.reload.assigned_to.full_name).to eq "Frank Yee"
        expect(claim.policy).to eq StudentLoans
      end
      [twenty_sixth_claim, thirtieth_claim, thirty_fifth_claim].each do |claim|
        expect(claim.reload.assigned_to).to be_nil
      end
    end

    scenario "when no claims for specified policy awaiting assignment" do
      [
        first_claim,
        second_claim,
        sixteenth_claim,
        seventeenth_claim,
        eighteenth_claim,
        nineteenth_claim,
        twenty_first_claim,
        twenty_second_claim,
        twenty_third_claim
      ].each do |claim|
        claim.assigned_to = frank
        claim.save

        expect(claim.reload.assigned_to.full_name).to eq frank.full_name
      end

      click_on "View claims"

      select "Sarah Strawbridge", from: "allocate_to_team_member"
      select "Student Loans", from: "allocate_to_policy"

      click_on "Allocate"

      within(".govuk-flash__notice") do
        expect(page).to have_text I18n.t("admin.allocations.bulk_allocate.info", allocate_to_policy: "Student Loans", dfe_user: sarah.full_name)
      end

      student_loan_claims.each do |claim|
        expect(claim.reload.assigned_to.full_name).to eq "Frank Yee"
      end

      early_career_payment_claims.each do |claim|
        expect(claim.reload.assigned_to).to be_nil
      end

      expect(page).to have_button "Allocate claims", disabled: false
    end
  end

  context "with all claims allocated" do
    scenario "unallocate All of Abdul Rafiq's claims" do
      Claim.awaiting_decision.update_all(assigned_to_id: abdul.id)

      click_on "View claims"

      @submitted_claims.each do |claim|
        expect(claim.reload.assigned_to.full_name).to eq "Abdul Rafiq"
      end

      expect(page).to have_button "Allocate claims", disabled: true

      select "Abdul Rafiq", from: "allocate_to_team_member"
      click_on "Unallocate"

      within(".govuk-flash__notice") do
        expect(page).to have_text I18n.t("admin.allocations.bulk_deallocate.success", allocate_to_policy: "", dfe_user: abdul.full_name).squeeze(" ")
      end

      @submitted_claims.each do |claim|
        expect(claim.reload.assigned_to).to be_nil
      end

      expect(page).to have_button "Allocate claims", disabled: false
    end

    scenario "unallocate Frank Yee's Early Career Payments claims" do
      Claim.awaiting_decision.update_all(assigned_to_id: frank.id)

      click_on "View claims"

      @submitted_claims.each do |claim|
        expect(claim.reload.assigned_to.full_name).to eq "Frank Yee"
      end

      expect(page).to have_button "Allocate claims", disabled: true

      select "Frank Yee", from: "allocate_to_team_member"
      select "Early-Career Payments", from: "allocate_to_policy"
      click_on "Unallocate"

      within(".govuk-flash__notice") do
        expect(page).to have_text I18n.t("admin.allocations.bulk_deallocate.success", allocate_to_policy: "Early Career Payments", dfe_user: frank.full_name)
      end

      student_loan_claims.each do |claim|
        expect(claim.reload.assigned_to.full_name).to eq "Frank Yee"
      end

      early_career_payment_claims.each do |claim|
        expect(claim.reload.assigned_to).to be_nil
      end

      expect(page).to have_button "Allocate claims", disabled: false
    end

    scenario "when zero claims for policy" do
      Claim.awaiting_decision.update_all(assigned_to_id: tripti.id)

      click_on "View claims"

      @submitted_claims.each do |claim|
        expect(claim.reload.assigned_to.full_name).to eq "Tripti Kumar"
      end

      expect(page).to have_button "Allocate claims", disabled: true

      select "Abdul Rafiq", from: "allocate_to_team_member"
      select "Early-Career Payments", from: "allocate_to_policy"
      click_on "Unallocate"

      within(".govuk-flash__notice") do
        expect(page).to have_text I18n.t("admin.allocations.bulk_deallocate.info", allocate_to_policy: "Early Career Payments", dfe_user: abdul.full_name)
      end

      student_loan_claims.each do |claim|
        expect(claim.reload.assigned_to.full_name).to eq "Tripti Kumar"
      end
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
