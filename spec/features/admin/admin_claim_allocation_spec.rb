require "rails_helper"

RSpec.feature "Claims awaiting a decision" do
  let(:expected_policy_select_options) do
    [
      "All",
      "Student Loans",
      "Early-Career Payments",
      "School Targeted Retention Incentive",
      "International Relocation Payments",
      "Further Education Targeted Retention Incentive",
      "Early Years"
    ]
  end

  before do
    create(:journey_configuration, :student_loans)
    create(:journey_configuration, :additional_payments)
    create(:journey_configuration, :get_a_teacher_relocation_payment)

    submitted_claims = []
    @signed_in_user = sign_in_as_service_operator

    # index: 0-1
    submitted_claims << create_list(:claim, 2, :submitted, policy: Policies::StudentLoans)

    # index: 2-14
    submitted_claims << create_list(:claim, 13, :submitted, policy: Policies::EarlyCareerPayments)

    # index: 15-18
    submitted_claims << create_list(:claim, 4, :submitted, policy: Policies::StudentLoans)

    # index: 19
    submitted_claims << create_list(:claim, 1, :submitted, policy: Policies::EarlyCareerPayments)

    # index: 20-22
    submitted_claims << create_list(:claim, 3, :submitted, policy: Policies::StudentLoans)

    # index: 23-34
    submitted_claims << create_list(:claim, 12, :submitted, policy: Policies::EarlyCareerPayments)

    # index: 35-38
    submitted_claims << create_list(:claim, 4, :submitted, policy: Policies::LevellingUpPremiumPayments)

    # index: 39
    submitted_claims << create_list(:claim, 1, :submitted, policy: Policies::InternationalRelocationPayments)

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
  let(:thirty_ninth_claim) { @submitted_claims[38] }

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
      @submitted_claims.slice(2..14),
      twentieth_claim,
      @submitted_claims.slice(23..34)
    ].flatten
  end

  let(:international_relocation_payment_claims) { [thirty_ninth_claim] }

  let(:levelling_up_premium_payments) { @submitted_claims.slice(36...35) }

  let!(:sarah) { create(:dfe_signin_user, given_name: "Sarah", family_name: "Strawbridge", organisation_name: "Department for Education", role_codes: [DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE]) }
  let!(:frank) { create(:dfe_signin_user, given_name: "Frank", family_name: "Yee", organisation_name: "Department for Education", role_codes: [DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE]) }
  let!(:abdul) { create(:dfe_signin_user, given_name: "Abdul", family_name: "Rafiq", organisation_name: "Department for Education", role_codes: [DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE]) }
  let!(:deleted_user) { create(:dfe_signin_user, :deleted, given_name: "Deleted", family_name: "User", organisation_name: "Department for Education", role_codes: [DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE]) }
  let!(:tripti) { create(:dfe_signin_user, given_name: "Tripti", family_name: "Kumar", organisation_name: "DfE Payroll", role_codes: [DfeSignIn::User::PAYROLL_OPERATOR_DFE_SIGN_IN_ROLE_CODE]) }

  context "with more than 25 claims" do
    scenario "assign first 25 to one Claim's checker" do
      click_on "View claims"

      within("#allocations") do
        expect(page).to have_select("allocate_to_team_member", options: ["Aaron Admin", "Sarah Strawbridge", "Frank Yee", "Abdul Rafiq"])
        expect(page).to have_select("allocate_to_policy", options: expected_policy_select_options)
        expect(page).to have_button("Allocate claims", disabled: false)
        expect(page).to have_button("Unallocate claims")
      end
      expect(@submitted_claims.size).to eq 40

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

    scenario "assign 5 claims to one Claim's checker" do
      click_on "View claims"

      expect(@submitted_claims.size).to eq 40

      select "Frank Yee", from: "allocate_to_team_member"
      select "All", from: "allocate_to_policy"
      select "10", from: "allocate_claim_count"

      click_on "Allocate claims"

      within(".govuk-flash__notice") do
        expect(page).to have_text I18n.t(
          "admin.allocations.bulk_allocate.success",
          quantity: 10,
          pluralized_or_singular_claim: "claims",
          allocate_to_policy: "",
          dfe_user: frank.full_name.titleize
        ).squeeze(" ")
      end

      @submitted_claims[0..9].each do |claim|
        expect(claim.reload.assigned_to.full_name).to eq "Frank Yee"
      end

      @submitted_claims[10..].each do |claim|
        expect(claim.reload.assigned_to).to be_nil
      end
    end

    scenario "assign outstanding 10 claims when 25 already allocated" do
      @submitted_claims.slice(0..24).each do |claim|
        claim.assigned_to = @signed_in_user
        claim.save

        expect(claim.reload.assigned_to.full_name).to eq "Aaron Admin"
      end

      click_on "View claims"

      select "Frank Yee", from: "allocate_to_team_member"
      select "All", from: "allocate_to_policy"

      click_on "Allocate"

      within(".govuk-flash__notice") do
        expect(page).to have_text I18n.t(
          "admin.allocations.bulk_allocate.success",
          quantity: 15,
          pluralized_or_singular_claim: "claims",
          allocate_to_policy: "",
          dfe_user: frank.full_name.titleize
        ).squeeze(" ")
      end

      @submitted_claims.slice(25, 10).each do |claim|
        expect(claim.reload.assigned_to.full_name).to eq "Frank Yee"
      end

      expect(page).to have_button "Allocate claims", disabled: true
    end
  end

  context "when assigning by policy" do
    scenario "Student Loans" do
      click_on "View claims"

      expect(@submitted_claims.size).to eq 40

      within("#allocations") do
        expect(page).to have_select("allocate_to_team_member", options: ["Aaron Admin", "Sarah Strawbridge", "Frank Yee", "Abdul Rafiq"])
        expect(page).to have_select("allocate_to_policy", options: expected_policy_select_options)
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
        expect(claim.policy).to eq Policies::StudentLoans
      end
      [twenty_sixth_claim, thirtieth_claim, thirty_fifth_claim].each do |claim|
        expect(claim.reload.assigned_to).to be_nil
      end
    end

    scenario "International Relocation Payments" do
      click_on "View claims"

      within("#allocations") do
        expect(page).to have_select("allocate_to_team_member", options: ["Aaron Admin", "Sarah Strawbridge", "Frank Yee", "Abdul Rafiq"])
        expect(page).to have_select("allocate_to_policy", options: expected_policy_select_options)
        expect(page).to have_button("Allocate claims", disabled: false)
        expect(page).to have_button("Unallocate claims")
      end

      expect(thirty_ninth_claim.assigned_to).to be_nil
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

      expect(page).to have_text "Are you sure you want to unassign claims from Abdul Rafiq?"

      click_on "Unassign"

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

      expect(page).to have_text "Are you sure you want to unassign Early Career Payments claims from Frank Yee?"

      click_on "Unassign"

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

    scenario "when deallocation is not confirmed" do
      Claim.awaiting_decision.update_all(assigned_to_id: abdul.id)

      click_on "View claims"

      @submitted_claims.each do |claim|
        expect(claim.reload.assigned_to.full_name).to eq "Abdul Rafiq"
      end

      expect(page).to have_button "Allocate claims", disabled: true

      select "Abdul Rafiq", from: "allocate_to_team_member"
      click_on "Unallocate"

      expect(page).to have_text "Are you sure you want to unassign claims from Abdul Rafiq?"

      click_on "Cancel"

      expect(current_path).to eql(admin_claims_path)

      @submitted_claims.each do |claim|
        expect(claim.reload.assigned_to.full_name).to eq "Abdul Rafiq"
      end

      expect(page).to have_button "Allocate claims", disabled: true
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

      expect(page).to have_text "Are you sure you want to unassign Early Career Payments claims from Abdul Rafiq?"

      click_on "Unassign"

      within(".govuk-flash__notice") do
        expect(page).to have_text I18n.t("admin.allocations.bulk_deallocate.info", allocate_to_policy: "Early Career Payments", dfe_user: abdul.full_name)
      end

      student_loan_claims.each do |claim|
        expect(claim.reload.assigned_to.full_name).to eq "Tripti Kumar"
      end
    end
  end
end
