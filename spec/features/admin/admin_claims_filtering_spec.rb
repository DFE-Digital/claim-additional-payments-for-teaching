require "rails_helper"

RSpec.feature "Admin claim filtering" do
  before do
    create(:journey_configuration, :additional_payments)
  end

  let!(:user) { sign_in_as_service_operator }
  let!(:mary) { create(:dfe_signin_user, given_name: "mary", family_name: "wasu-wabi", organisation_name: "Department for Education", role_codes: [DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE]) }
  let!(:valentino) { create(:dfe_signin_user, given_name: "Valentino", family_name: "Ricci", organisation_name: "Department for Education", role_codes: [DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE]) }
  let!(:mette) { create(:dfe_signin_user, given_name: "Mette", family_name: "Jørgensen", organisation_name: "Department for Education", role_codes: [DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE]) }
  let!(:deleted_user) { create(:dfe_signin_user, :deleted, given_name: "Deleted", family_name: "User", organisation_name: "Department for Education", role_codes: [DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE]) }
  let!(:raj) { create(:dfe_signin_user, given_name: "raj", family_name: "sathikumar", organisation_name: "DfE Payroll", role_codes: [DfeSignIn::User::PAYROLL_OPERATOR_DFE_SIGN_IN_ROLE_CODE]) }

  let(:student_loans_claims_for_mette) { create_list(:claim, 4, :submitted, policy: Policies::StudentLoans, assigned_to: mette) }
  let(:student_loans_claims_for_valentino) { create_list(:claim, 1, :submitted, policy: Policies::StudentLoans, assigned_to: valentino) }
  let(:early_career_payments_claims_for_mary) { create_list(:claim, 2, :submitted, policy: Policies::EarlyCareerPayments, assigned_to: mary) }
  let(:early_career_payments_claims_for_mette) { create_list(:claim, 6, :submitted, policy: Policies::EarlyCareerPayments, assigned_to: mette) }
  let(:early_career_payments_claims_failed_bank_validation) { create_list(:claim, 2, :submitted, :bank_details_not_validated, policy: Policies::EarlyCareerPayments, assigned_to: mette) }
  let(:targeted_retention_incentive_claims_unassigned) { create_list(:claim, 2, :submitted, policy: Policies::TargetedRetentionIncentivePayments) }
  let(:held_claims) { create_list(:claim, 2, :submitted, :held) }
  let(:approved_awaiting_qa_claims) { create_list(:claim, 2, :approved, :flagged_for_qa, policy: Policies::TargetedRetentionIncentivePayments) }
  let(:auto_approved_awaiting_payroll_claims) { create_list(:claim, 2, :auto_approved, policy: Policies::TargetedRetentionIncentivePayments) }
  let(:approved_claim) { create(:claim, :approved, policy: Policies::TargetedRetentionIncentivePayments, assigned_to: mette, decision_creator: mary) }
  let(:further_education_claims_awaiting_provider_verification) { create_list(:claim, 2, :submitted, policy: Policies::FurtherEducationPayments, eligibility_trait: :not_verified, assigned_to: valentino) }
  let(:further_education_claims_provider_verification_email_not_sent) { create_list(:claim, 2, :submitted, policy: Policies::FurtherEducationPayments, eligibility_trait: :duplicate, assigned_to: valentino) }
  let(:rejected_claim) { create(:claim, :rejected, policy: Policies::TargetedRetentionIncentivePayments, assigned_to: valentino) }

  let!(:claims) do
    [
      student_loans_claims_for_mette,
      student_loans_claims_for_valentino,
      early_career_payments_claims_for_mary,
      early_career_payments_claims_for_mette,
      early_career_payments_claims_failed_bank_validation,
      targeted_retention_incentive_claims_unassigned,
      held_claims,
      approved_awaiting_qa_claims,
      auto_approved_awaiting_payroll_claims,
      approved_claim,
      further_education_claims_awaiting_provider_verification,
      further_education_claims_provider_verification_email_not_sent,
      rejected_claim
    ]
  end

  scenario "the service operator can filter claims by policy" do
    student_loan_claims = create_list(:claim, 2, :submitted, policy: Policies::StudentLoans) + student_loans_claims_for_mette + student_loans_claims_for_valentino
    ecp_claims = early_career_payments_claims_for_mary + early_career_payments_claims_for_mette + early_career_payments_claims_failed_bank_validation
    targeted_retention_incentive_claims = targeted_retention_incentive_claims_unassigned

    click_on "View claims"

    expect(page).to have_selector("td[text()='ECP']", count: 10)
    expect(page).to have_selector("td[text()='TSLR']", count: 7)
    expect(page).to have_selector("td[text()='STRI']", count: 2)
    expect(page).to have_selector("td[text()='FE']", count: 2)

    click_on "View claims"
    select "Student Loans", from: "filter-policy-field"
    click_on "Apply filters"

    student_loan_claims.each do |c|
      expect(page).to have_content(c.reference)
    end

    ecp_claims.each do |c|
      expect(page).to_not have_content(c.reference)
    end

    targeted_retention_incentive_claims.each do |c|
      expect(page).to_not have_content(c.reference)
    end
  end

  scenario "the service operator can filter by themselves or other team members" do
    click_on "View claims"

    expect(page).to have_selector("td[text()='TSLR']", count: 5)
    expect(page).to have_selector("td[text()='ECP']", count: 10)

    # Excludes payroll users and deleted users
    expect(page).to have_select("filter-team-member-field", options: ["All", "Unassigned", "#{user.given_name} #{user.family_name}", "Mary Wasu Wabi", "Valentino Ricci", "Mette Jørgensen"])

    select "Mette Jørgensen", from: "filter-team-member-field"
    click_on "Apply filters"

    expect_page_to_show_claims(
      student_loans_claims_for_mette,
      early_career_payments_claims_for_mette,
      early_career_payments_claims_failed_bank_validation
    )

    # Assigned to Mette
    select "Mette Jørgensen", from: "filter-team-member-field"
    select "Approved", from: "filter-status-field"
    click_on "Apply filters"
    expect(page).to have_content("1 claim approved")
    expect_page_to_show_claims(approved_claim)

    # Approved by Mary
    select "Mary Wasu Wabi", from: "filter-team-member-field"
    select "Approved", from: "filter-status-field"
    click_on "Apply filters"
    expect(page).to have_content("1 claim approved")
    expect(page).to have_content(approved_claim.reference)
  end

  scenario "filter unassigned claims" do
    click_on "View claims"
    select "Unassigned", from: "filter-team-member-field"
    click_on "Apply filters"

    expect(page).to have_selector("td[text()='STRI']", count: 2)

    expect_page_to_show_claims(targeted_retention_incentive_claims_unassigned)
  end

  scenario "filter claims by status" do
    click_on "View claims"

    expect_page_to_show_claims(
      student_loans_claims_for_mette,
      student_loans_claims_for_valentino,
      early_career_payments_claims_for_mary,
      early_career_payments_claims_for_mette,
      early_career_payments_claims_failed_bank_validation,
      targeted_retention_incentive_claims_unassigned,
      further_education_claims_provider_verification_email_not_sent
    )

    select "Awaiting provider verification", from: "filter-status-field"
    click_button "Apply filters"

    expect_page_to_show_claims(further_education_claims_awaiting_provider_verification)

    select "Awaiting decision - on hold", from: "filter-status-field"
    click_button "Apply filters"

    expect_page_to_show_claims(held_claims)

    select "Awaiting decision - failed bank details", from: "filter-status-field"
    click_button "Apply filters"

    expect_page_to_show_claims(early_career_payments_claims_failed_bank_validation)

    select "Approved awaiting QA", from: "filter-status-field"
    click_button "Apply filters"

    expect_page_to_show_claims(approved_awaiting_qa_claims)

    select "Approved awaiting payroll", from: "filter-status-field"
    click_button "Apply filters"
    expect_page_to_show_claims(auto_approved_awaiting_payroll_claims, approved_claim)

    select "Automatically approved awaiting payroll", from: "filter-status-field"
    click_button "Apply filters"

    expect_page_to_show_claims(auto_approved_awaiting_payroll_claims)

    select "Rejected", from: "filter-status-field"
    click_button "Apply filters"
    expect_page_to_show_claims(rejected_claim)
  end

  def expect_page_to_show_claims(*expected_claims)
    expected_claims.flatten.each do |c|
      expect(page).to have_content(c.reference)
    end
    (claims - expected_claims).flatten.each do |c|
      expect(page).to_not have_content(c.reference)
    end
  end
end
