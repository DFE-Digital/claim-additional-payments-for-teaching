require "rails_helper"

RSpec.describe "Reports" do
  it "allows admins to download the claim reports" do
    claim_with_failed_provider_check_report = create(
      :report,
      :claim_with_failed_provider_check
    )

    claim_with_failed_qualification_status_report = create(
      :report,
      :claim_with_failed_qualification_status
    )

    duplicate_approved_claims_report = create(
      :report,
      :duplicate_approved_claims
    )

    sign_in_as_service_operator

    visit "/admin/reports"

    click_on "Claims with failed provider check"

    expect(page.body).to eq claim_with_failed_provider_check_report.csv

    visit "/admin/reports"

    click_on "Claims with failed qualification status"

    expect(page.body).to eq claim_with_failed_qualification_status_report.csv

    visit "/admin/reports"

    click_on "Duplicate Approved Claims"

    expect(page.body).to eq duplicate_approved_claims_report.csv
  end
end
