require "rails_helper"

RSpec.feature "Admin view claim for FurtherEducationPayments" do
  let!(:journey_configuration) { create(:journey_configuration, "further_education_payments") }
  let(:eligibility) { create(:further_education_payments_eligibility, :eligible) }
  let(:eligibility_with_trn) { create(:further_education_payments_eligibility, :eligible, :with_trn) }
  let(:eligibility_verified) { create(:further_education_payments_eligibility, :verified) }
  let!(:claim) {
    create(
      :claim,
      :submitted,
      policy: Policies::FurtherEducationPayments,
      eligibility: eligibility
    )
  }
  let!(:claim_with_trn) {
    create(
      :claim,
      :submitted,
      policy: Policies::FurtherEducationPayments,
      eligibility: eligibility_with_trn
    )
  }
  let!(:claim_with_no_matching_details_task) {
    create(
      :claim,
      :submitted,
      policy: Policies::FurtherEducationPayments,
      eligibility: eligibility,
      email_address: claim_with_trn.email_address
    )
  }
  let!(:claim_with_matching_details_task_answered_yes) {
    create(
      :claim,
      :submitted,
      policy: Policies::FurtherEducationPayments,
      eligibility: eligibility
    )
  }
  let!(:claim_with_matching_details_task_answered_no) {
    create(
      :claim,
      :submitted,
      policy: Policies::FurtherEducationPayments,
      eligibility: eligibility
    )
  }
  let!(:verified_claim) {
    create(
      :claim,
      :submitted,
      policy: Policies::FurtherEducationPayments,
      eligibility: eligibility_verified
    )
  }

  before do
    sign_in_as_service_operator
    create(:task, claim: claim_with_matching_details_task_answered_yes, name: "matching_details", passed: true)
    create(:task, claim: claim_with_matching_details_task_answered_no, name: "matching_details", passed: false)
  end

  scenario "view claim summary for claim with no TRN" do
    visit admin_claims_path
    find("a[href='#{admin_claim_tasks_path(claim)}']").click
    expect(page).not_to have_content("Claim route")
    expect(page).not_to have_content("Not signed in with DfE Identity")
    expect(page).to have_content("Not provided")
    expect(page).to have_content("UK Provider Reference Number (UKPRN)")
    expect(page).to have_content(claim.school.ukprn)
  end

  scenario "view claim summary for claim with TRN" do
    visit admin_claims_path
    find("a[href='#{admin_claim_tasks_path(claim_with_trn)}']").click
    expect(page).not_to have_content("Not provided")
    expect(page).to have_content(claim_with_trn.eligibility.teacher_reference_number)
    expect(page).to have_content("UK Provider Reference Number (UKPRN)")
    expect(page).to have_content(claim_with_trn.school.ukprn)
  end

  scenario "Awaiting provider verification claim status" do
    visit admin_claims_path
    find("a[href='#{admin_claim_tasks_path(claim)}']").click
    expect(page).to have_content("Awaiting provider verification")

    visit admin_claims_path
    find("a[href='#{admin_claim_tasks_path(claim_with_no_matching_details_task)}']").click
    expect(page).to have_content("Awaiting decision - not on hold")

    visit admin_claims_path
    find("a[href='#{admin_claim_tasks_path(claim_with_matching_details_task_answered_yes)}']").click
    expect(page).to have_content("Awaiting provider verification")

    visit admin_claims_path
    find("a[href='#{admin_claim_tasks_path(claim_with_matching_details_task_answered_no)}']").click
    expect(page).to have_content("Awaiting decision - not on hold")

    visit admin_claims_path
    find("a[href='#{admin_claim_tasks_path(verified_claim)}']").click
    expect(page).to have_content("Awaiting decision - not on hold")
  end
end
