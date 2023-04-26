require "rails_helper"

RSpec.feature "Admin claim filtering" do
  before do
    create(:policy_configuration, :additional_payments)
  end

  let!(:user) { sign_in_as_service_operator }
  let!(:mary) { create(:dfe_signin_user, given_name: "mary", family_name: "wasu-wabi", organisation_name: "Department for Education", role_codes: [DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE]) }
  let!(:valentino) { create(:dfe_signin_user, given_name: "Valentino", family_name: "Ricci", organisation_name: "Department for Education", role_codes: [DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE]) }
  let!(:mette) { create(:dfe_signin_user, given_name: "Mette", family_name: "Jørgensen", organisation_name: "Department for Education", role_codes: [DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE]) }
  let!(:deleted_user) { create(:dfe_signin_user, :deleted, given_name: "Deleted", family_name: "User", organisation_name: "Department for Education", role_codes: [DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE]) }
  let!(:raj) { create(:dfe_signin_user, given_name: "raj", family_name: "sathikumar", organisation_name: "DfE Payroll", role_codes: [DfeSignIn::User::PAYROLL_OPERATOR_DFE_SIGN_IN_ROLE_CODE]) }

  let!(:student_loans_claims_for_mette) { create_list(:claim, 4, :submitted, policy: StudentLoans, assigned_to: mette) }
  let!(:student_loans_claims_for_valentino) { create_list(:claim, 1, :submitted, policy: StudentLoans, assigned_to: valentino) }
  let!(:early_career_payments_claims_for_mary) { create_list(:claim, 2, :submitted, policy: EarlyCareerPayments, assigned_to: mary) }
  let!(:early_career_payments_claims_for_mette) { create_list(:claim, 6, :submitted, policy: EarlyCareerPayments, assigned_to: mette) }
  let!(:early_career_payments_claims_failed_bank_validation) { create_list(:claim, 2, :submitted, :bank_details_not_validated, policy: EarlyCareerPayments, assigned_to: mette) }
  let!(:lup_claims_unassigned) { create_list(:claim, 2, :submitted, policy: LevellingUpPremiumPayments) }
  let!(:held_claims) { create_list(:claim, 2, :submitted, :held) }

  scenario "the service operator can filter claims by policy" do
    maths_and_physics_claims = create_list(:claim, 3, :submitted, policy: MathsAndPhysics)
    student_loan_claims = create_list(:claim, 2, :submitted, policy: StudentLoans)

    click_on "View claims"

    expect(page.find("table")).to have_content("Maths and Physics").exactly(3).times
    expect(page.find("table")).to have_content("TSLR").exactly(7).times

    click_on "View claims"
    select "Maths and Physics", from: "policy"
    click_on "Apply filters"

    maths_and_physics_claims.each do |c|
      expect(page).to have_content(c.reference)
    end

    student_loan_claims.each do |c|
      expect(page).to_not have_content(c.reference)
    end
  end

  scenario "the service operater can filter by themselves or other team members" do
    click_on "View claims"

    expect(page.find("table")).to have_content("TSLR").exactly(5).times
    expect(page.find("table")).to have_content("ECP").exactly(10).times

    click_on "View claims"

    # Excludes payroll users and deleted users
    expect(page).to have_select("team_member", options: ["All", "Unassigned", "#{user.given_name} #{user.family_name}", "Mary Wasu Wabi", "Valentino Ricci", "Mette Jørgensen"])

    select "Mette Jørgensen", from: "team_member"
    click_on "Apply filters"

    [
      student_loans_claims_for_mette,
      early_career_payments_claims_for_mette,
      early_career_payments_claims_failed_bank_validation
    ].flatten.each do |c|
      expect(page).to have_content(c.reference)
    end

    [
      student_loans_claims_for_valentino,
      early_career_payments_claims_for_mary,
      lup_claims_unassigned
    ].flatten.each do |c|
      expect(page).to_not have_content(c.reference)
    end
  end

  scenario "filter unassigned claims" do
    click_on "View claims"
    select "Unassigned", from: "team_member"
    click_on "Apply filters"

    expect(page.find("table")).to have_content("LUP").exactly(2).times

    lup_claims_unassigned.each do |c|
      expect(page).to have_content(c.reference)
    end

    [
      student_loans_claims_for_mette,
      student_loans_claims_for_valentino,
      early_career_payments_claims_for_mary,
      early_career_payments_claims_for_mette,
      early_career_payments_claims_failed_bank_validation
    ].flatten.each do |c|
      expect(page).to_not have_content(c.reference)
    end
  end

  scenario "filter claims by status" do
    click_on "View claims"

    held_claims.each do |c|
      expect(page).to_not have_content(c.reference)
    end

    [
      student_loans_claims_for_mette,
      student_loans_claims_for_valentino,
      early_career_payments_claims_for_mary,
      early_career_payments_claims_for_mette,
      early_career_payments_claims_failed_bank_validation,
      lup_claims_unassigned
    ].flatten.each do |c|
      expect(page).to have_content(c.reference)
    end

    select "Awaiting decision - on hold", from: "Status:"
    click_button "Apply filters"

    held_claims.each do |c|
      expect(page).to have_content(c.reference)
    end

    [
      student_loans_claims_for_mette,
      student_loans_claims_for_valentino,
      early_career_payments_claims_for_mary,
      early_career_payments_claims_for_mette,
      early_career_payments_claims_failed_bank_validation,
      lup_claims_unassigned
    ].flatten.each do |c|
      expect(page).not_to have_content(c.reference)
    end

    select "Awaiting decision - failed bank details", from: "Status:"
    click_button "Apply filters"

    early_career_payments_claims_failed_bank_validation.each do |c|
      expect(page).to have_content(c.reference)
    end
  end
end
