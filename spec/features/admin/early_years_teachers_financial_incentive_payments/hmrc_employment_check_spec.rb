require "rails_helper"

RSpec.describe "EYTFI admin HMRC employment check" do
  it "shows each HMRC employment alongside uploaded evidence" do
    claim = create(
      :claim,
      :submitted,
      policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
      eligibility_attributes: {
        hmrc_employment_check_passed: true,
        hmrc_response_status: 200,
        hmrc_response_body: {
          employments: [
            {
              employer: {
                name: "Oak Tree Nursery",
                address: {
                  line1: "1 High Street",
                  postcode: "SW1A 1AA"
                }
              },
              startDate: "2025-01-01",
              endDate: "2026-01-01"
            },
            {
              employer: {
                name: "Sunny Days Nursery",
                address: {
                  postcode: "TS1 2AB"
                }
              }
            }
          ]
        }.to_json
      }
    )

    claim.eligibility.employment_proofs.attach(
      io: File.open(
        Rails.root.join("spec/fixtures/files/employment_proof.pdf")
      ),
      filename: "employment_proof.pdf",
      content_type: "application/pdf"
    )

    claim.eligibility.employment_proofs.first.blob.update!(
      malware_scan_result: ActiveStorage::Blob::MALWARE_SCAN_RESULT_PASSED,
      malware_scanned_at: Time.zone.now
    )

    sign_in_as_service_admin
    visit admin_claim_task_path(claim, "employment")

    expect(page).to have_link(
      "employment_proof.pdf",
      target: "_blank"
    )

    within("#hmrc-employment-check") do
      expect(page).to have_text("HMRC employment check")

      expect(page).to have_selector("h3", text: "Employment 1")

      expect(page).to have_selector("h3", text: "Employment 2")

      within(all("dl").first) do
        expect(page).to have_summary_item(
          key: "Employer name",
          value: "Oak Tree Nursery"
        )

        expect(page).to have_summary_item(
          key: "Address line 1",
          value: "1 High Street"
        )

        expect(page).to have_summary_item(
          key: "Address postcode",
          value: "SW1A 1AA"
        )

        expect(page).to have_summary_item(
          key: "Employment start date",
          value: "2025-01-01"
        )

        expect(page).to have_summary_item(
          key: "Employment end date",
          value: "2026-01-01"
        )
      end

      within(all("dl")[1]) do
        expect(page).to have_summary_item(
          key: "Employer name",
          value: "Sunny Days Nursery"
        )

        expect(page).to have_summary_item(
          key: "Employment start date",
          value: "Not returned"
        )
      end
    end
  end

  it "shows when HMRC cannot find the claimant" do
    claim = create(
      :claim,
      :submitted,
      policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
      eligibility_attributes: {
        hmrc_response_status: 404,
        hmrc_response_body: "not found"
      }
    )

    sign_in_as_service_admin

    visit admin_claim_task_path(claim, "employment")

    expect(page).to have_text("Claimant not found on HMRC.")
    expect(page).to have_text("Uploaded evidence")
  end

  it "shows an HMRC error without exposing the raw error response" do
    claim = create(
      :claim,
      :submitted,
      policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
      eligibility_attributes: {
        hmrc_response_status: 500,
        hmrc_response_body: "internal server error"
      }
    )

    sign_in_as_service_admin

    visit admin_claim_task_path(claim, "employment")

    expect(page).to have_text(
      "Unable to retrieve employment records due to an HMRC error."
    )

    expect(page).not_to have_text("internal server error")
  end

  it "shows when no employment records were returned" do
    claim = create(
      :claim,
      :submitted,
      policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
      eligibility_attributes: {
        hmrc_response_status: 200,
        hmrc_response_body: {
          employments: []
        }.to_json
      }
    )

    sign_in_as_service_admin

    visit admin_claim_task_path(claim, "employment")

    expect(page).to have_text(
      "HMRC returned no employment records for this claimant."
    )
  end

  it "handles an unreadable successful response" do
    claim = create(
      :claim,
      :submitted,
      policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
      eligibility_attributes: {
        hmrc_response_status: 200,
        hmrc_response_body: "invalid JSON"
      }
    )

    sign_in_as_service_admin

    visit admin_claim_task_path(claim, "employment")

    expect(page).to have_text(
      "The employment response from HMRC could not be read."
    )
  end

  it "shows when the HMRC check has not completed" do
    claim = create(
      :claim,
      :submitted,
      policy: Policies::EarlyYearsTeachersFinancialIncentivePayments
    )

    sign_in_as_service_admin

    visit admin_claim_task_path(claim, "employment")

    expect(page).to have_text(
      "The HMRC employment check has not been completed."
    )
  end
end
