require "rails_helper"

RSpec.feature "Admin view claim for FurtherEducationPayments" do
  let!(:journey_configuration) { create(:journey_configuration, "further_education_payments") }
  let(:eligibility) { create(:further_education_payments_eligibility, :eligible) }
  let(:eligibility_with_trn) { create(:further_education_payments_eligibility, :eligible, :with_trn) }
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

  scenario "view claim summary for claim with no TRN" do
    sign_in_as_service_operator
    visit admin_claims_path
    find("a[href='#{admin_claim_tasks_path(claim)}']").click
    expect(page).not_to have_content("Claim route")
    expect(page).not_to have_content("Not signed in with DfE Identity")
    expect(page).to have_content("Not provided")
    expect(page).to have_content("UK Provider Reference Number (UKPRN)")
    expect(page).to have_content(claim.school.ukprn)
  end

  scenario "view claim summary for claim with TRN" do
    sign_in_as_service_operator
    visit admin_claims_path
    find("a[href='#{admin_claim_tasks_path(claim_with_trn)}']").click
    expect(page).not_to have_content("Not provided")
    expect(page).to have_content(claim_with_trn.eligibility.teacher_reference_number)
    expect(page).to have_content("UK Provider Reference Number (UKPRN)")
    expect(page).to have_content(claim_with_trn.school.ukprn)
  end
end