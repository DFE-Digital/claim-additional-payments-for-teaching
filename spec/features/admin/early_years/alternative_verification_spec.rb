require "rails_helper"

RSpec.describe "EY claim and alternative verification task" do
  before do
    sign_in_as_service_operator

    AutomatedChecks::ClaimVerifiers::OneLoginIdentity.new(claim:).perform
  end

  context "when claimant passes OL idv" do
    let(:claim) do
      create(
        :claim,
        :submitted,
        :with_onelogin_idv_data,
        policy: Policies::EarlyYearsPayments
      )
    end

    scenario "task is not visible" do
      visit admin_claim_path(claim)
      click_on "View tasks"

      expect(task_status("One Login identity check")).to eql "Passed"
      expect(page).not_to have_text "Alternative verification"
    end
  end

  context "when claimant fails OL idv" do
    let(:claim) do
      create(
        :claim,
        :submitted,
        :with_failed_ol_idv,
        policy: Policies::EarlyYearsPayments
      )
    end

    scenario "awaiting provider response" do
      visit admin_claim_path(claim)
      click_on "View tasks"

      expect(task_status("One Login identity check")).to eql "No data"
      expect(task_status("Alternative verification")).to eql "Incomplete"
      click_link "Confirm the provider has verified the claimant’s identity"

      expect(page).to have_text "Awaiting provider response"
      expect(page).to have_text "Do the details provided by the claimant match the provider’s responses?"
    end

    context "when claimant does not work at provider" do
      let(:claim) do
        create(
          :claim,
          :submitted,
          :with_failed_ol_idv,
          policy: Policies::EarlyYearsPayments,
          eligibility:
        )
      end

      let(:eligibility) do
        create(
          :early_years_payments_eligibility,
          :with_eligible_ey_provider,
          :provider_claim_submitted,
          alternative_idv_claimant_employed_by_nursery: false
        )
      end

      before do
        perform_enqueued_jobs do
          Policies::EarlyYearsPayments.alternative_idv_completed!(claim)
        end
      end

      scenario "task is auto failed" do
        visit admin_claim_path(claim)
        click_on "View tasks"

        expect(task_status("One Login identity check")).to eql "No data"
        expect(task_status("Alternative verification")).to eql "Failed"
        click_link "Confirm the provider has verified the claimant’s identity"

        expect(page).to have_text "This task was performed by an automated check on"
      end
    end

    context "provider agrees with claimant answers" do
      let(:claim) do
        create(
          :claim,
          :submitted,
          :with_failed_ol_idv,
          policy: Policies::EarlyYearsPayments,
          eligibility:,
          date_of_birth: Date.new(1970, 1, 1),
          postcode: "EC1N 2TD",
          national_insurance_number: "AB123456C",
          email_address: "claimant@example.com"
        )
      end

      let(:eligibility) do
        create(
          :early_years_payments_eligibility,
          :with_eligible_ey_provider,
          :provider_claim_submitted,
          alternative_idv_claimant_employed_by_nursery: true,
          alternative_idv_claimant_date_of_birth: Date.new(1970, 1, 1),
          alternative_idv_claimant_postcode: "EC1N 2TD",
          alternative_idv_claimant_national_insurance_number: "AB123456C",
          alternative_idv_claimant_bank_details_match: true,
          alternative_idv_claimant_email: "claimant@example.com"
        )
      end

      before do
        perform_enqueued_jobs do
          Policies::EarlyYearsPayments.alternative_idv_completed!(claim)
        end
      end

      scenario "task is auto passed" do
        visit admin_claim_path(claim)
        click_on "View tasks"

        expect(task_status("One Login identity check")).to eql "No data"
        expect(task_status("Alternative verification")).to eql "Passed"
        click_link "Confirm the provider has verified the claimant’s identity"

        expect(page).to have_text "This task was performed by an automated check on"
      end
    end

    context "partial match" do
      let(:claim) do
        create(
          :claim,
          :submitted,
          :with_failed_ol_idv,
          policy: Policies::EarlyYearsPayments,
          eligibility:,
          date_of_birth: Date.new(1970, 1, 1),
          postcode: "EC1N 2TD",
          national_insurance_number: "AB123456C",
          email_address: "claimant@example.com"
        )
      end

      let(:eligibility) do
        create(
          :early_years_payments_eligibility,
          :with_eligible_ey_provider,
          :provider_claim_submitted,
          alternative_idv_claimant_employed_by_nursery: true,
          alternative_idv_claimant_date_of_birth: Date.new(1970, 1, 1),
          alternative_idv_claimant_postcode: "EC1N 3TD",
          alternative_idv_claimant_national_insurance_number: "AB123456C",
          alternative_idv_claimant_bank_details_match: true,
          alternative_idv_claimant_email: "claimant@example.com"
        )
      end

      before do
        perform_enqueued_jobs do
          Policies::EarlyYearsPayments.alternative_idv_completed!(claim)
        end
      end

      scenario "shows manual task" do
        visit admin_claim_path(claim)
        click_on "View tasks"

        expect(task_status("One Login identity check")).to eql "No data"
        expect(task_status("Alternative verification")).to eql "Incomplete"
        click_link "Confirm the provider has verified the claimant’s identity"

        expect(page).not_to have_text "Awaiting provider response"

        expect(page).to have_text "Do the details provided by the claimant match the provider’s responses?"
        choose "Yes"
        click_button "Save and continue"

        click_link "View tasks"

        expect(task_status("Alternative verification")).to eql "Passed"
      end
    end
  end
end
