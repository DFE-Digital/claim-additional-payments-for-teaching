require "rails_helper"

RSpec.feature "Admin view claim for FurtherEducationPayments" do
  let!(:journey_configuration) { create(:journey_configuration, "further_education_payments") }
  let(:eligibility_with_trn) { create(:further_education_payments_eligibility, :eligible, :with_trn) }
  let!(:claim) {
    create(
      :claim,
      :submitted,
      policy: Policies::FurtherEducationPayments,
      eligibility_trait: :duplicate
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
  let!(:claim_not_verified) {
    create(
      :claim,
      :submitted,
      policy: Policies::FurtherEducationPayments,
      eligibility_trait: :not_verified
    )
  }
  let!(:claim_with_duplicates_no_provider_email_sent) {
    create(
      :claim,
      :submitted,
      policy: Policies::FurtherEducationPayments,
      eligibility_trait: :duplicate
    )
  }
  let!(:claim_with_duplicates_provider_email_sent) {
    create(
      :claim,
      :submitted,
      policy: Policies::FurtherEducationPayments,
      eligibility_trait: :duplicate
    )
  }
  let!(:verified_claim) {
    create(
      :claim,
      :submitted,
      policy: Policies::FurtherEducationPayments,
      eligibility_trait: :verified
    )
  }

  before do
    sign_in_as_service_operator
    create(:note, claim: claim_with_duplicates_provider_email_sent, label: "provider_verification")
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
    visit admin_claims_path(filter: {status: "awaiting_provider_verification"})
    find("a[href='#{admin_claim_tasks_path(claim_not_verified)}']").click
    expect(page).to have_content("Awaiting provider verification")

    visit admin_claims_path
    click_link "Clear filters"
    find("a[href='#{admin_claim_tasks_path(claim_with_duplicates_no_provider_email_sent)}']").click
    expect(page).to have_content("Awaiting decision - not on hold")

    visit admin_claims_path(filter: {status: "awaiting_provider_verification"})
    find("a[href='#{admin_claim_tasks_path(claim_with_duplicates_provider_email_sent)}']").click
    expect(page).to have_content("Awaiting provider verification")

    visit admin_claims_path
    click_link "Clear filters"
    find("a[href='#{admin_claim_tasks_path(verified_claim)}']").click
    expect(page).to have_content("Awaiting decision - not on hold")
  end
end
