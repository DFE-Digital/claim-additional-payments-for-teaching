require "rails_helper"

RSpec.feature "Admin view claim for EarlyYearsPayments" do
  let(:eligible_ey_provider) { create(:eligible_ey_provider) }
  let(:eligibility) {
    create(
      :early_years_payments_eligibility,
      :eligible,
      :provider_claim_submitted,
      nursery_urn: eligible_ey_provider.urn
    )
  }
  let!(:claim) {
    create(
      :claim,
      :submitted,
      policy: Policies::EarlyYearsPayments,
      eligibility:,
      paye_reference: "123/ABC"
    )
  }
  let(:claim_with_personal_data_removed) { create(:claim, :rejected, :personal_data_removed) }

  before do
    sign_in_as_service_operator
  end

  scenario "view claim summary" do
    visit admin_claims_path
    find("a[href='#{admin_claim_tasks_path(claim)}']").click
    expect(page).not_to have_content("Claim route")
    expect(page).not_to have_content("Not signed in with DfE Identity")
    expect(page).to have_summary_item(key: "Applicant name", value: claim.full_name)
    expect(page).to have_summary_item(key: "NI number", value: claim.national_insurance_number)
    expect(page).to have_summary_item(key: "Contact email", value: claim.email_address)
    expect(page).to have_summary_item(key: "Provider email", value: eligible_ey_provider.primary_key_contact_email_address)
    expect(page).to have_summary_item(key: "Start date", value: claim.eligibility.start_date.strftime(I18n.t("date.formats.default")))
    expect(page).to have_summary_item(key: "Date of birth", value: claim.date_of_birth.strftime(I18n.t("date.formats.day_month_year")))
    expect(page).to have_summary_item(key: "Mobile number", value: claim.mobile_number)
    expect(page).to have_summary_item(key: "Reference", value: claim.reference)
    expect(page).to have_summary_item(key: "Submitted", value: claim.submitted_at.strftime(I18n.t("time.formats.default")))
    expect(page).to have_summary_item(key: "Decision due", value: claim.decision_deadline_date.strftime(I18n.t("date.formats.default")))
    expect(page).to have_summary_item(key: "Status", value: "Awaiting decision - not on hold")
    expect(page).to have_summary_item(key: "Claim amount", value: "£0.00")
    expect(page).to have_summary_item(key: "PAYE reference", value: "123/ABC")
  end

  scenario "view claim summary when personal data has been removed" do
    visit admin_claim_path(claim_with_personal_data_removed)

    expect(page).to have_content("personal data removed")
    expect(page).to have_content("Full name Removed")
    expect(page).to have_content("Date of birth Removed")
    expect(page).to have_content("National Insurance number Removed")
    expect(page).to have_content("Address Removed")
  end
end
