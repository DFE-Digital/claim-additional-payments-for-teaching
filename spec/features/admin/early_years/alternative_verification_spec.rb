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
      click_link "Confirm the claimant made the claim"

      click_link "Confirm the provider has verified the claimant’s employment"

      expect(page).to have_text "Awaiting provider response"
      expect(page).to have_text "Do the personal details provided by the claimant match the details from the provider?"
    end

    xcontext "when claimant does not work at provider" do
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

        expect(page).to have_text(
          "The provider told us that they do not employ Edna Krabapple"
        )

        expect(page).to have_text "This task was performed by an automated check on"
      end
    end

    context "provider agrees with claimant personal and bank details answers" do
      let(:claim) do
        create(
          :claim,
          :submitted,
          :with_failed_ol_idv,
          policy: Policies::EarlyYearsPayments,
          eligibility:,
          date_of_birth: Date.new(1970, 1, 1),
          postcode: "ec1n 2td",
          national_insurance_number: "ab123456c",
          email_address: "claimant@example.com",
          first_name: "Edna",
          surname: "Krabapple"
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
          alternative_idv_claimant_email: "CLAIMANT@example.com"
        )
      end

      before do
        perform_enqueued_jobs do
          Policies::EarlyYearsPayments.alternative_idv_completed!(claim)
        end
      end

      scenario "admin passes the task" do
        visit admin_claim_path(claim)
        click_on "View tasks"

        expect(task_status("One Login identity check")).to eql "No data"
        expect(task_status("Alternative verification")).to eql "Incomplete"
        click_link "Confirm the provider has verified the claimant’s identity"

        expect(page).to have_text(
          "The provider told us that they employ Edna Krabapple"
        )

        within_fieldset(
          "Do the personal details provided by the claimant match the details " \
          "from the provider?"
        ) do
          choose "Yes"
        end

        expect(page).to have_text(
          "The provider told us that they recognise the bank account details " \
          "that Edna Krabapple submitted."
        )

        within_fieldset(
          "Has Edna Krabapple provided their own bank account details?"
        ) do
          choose "Yes"
        end

        click_button "Save and continue"

        visit admin_claim_tasks_path(claim)

        expect(task_status("Alternative verification")).to eq "Passed"
      end
    end

    context "provider disagrees with claimant bank details answers" do
      let(:claim) do
        create(
          :claim,
          :submitted,
          :with_failed_ol_idv,
          policy: Policies::EarlyYearsPayments,
          eligibility:,
          date_of_birth: Date.new(1970, 1, 1),
          postcode: "ec1n 2td",
          national_insurance_number: "ab123456c",
          email_address: "claimant@example.com",
          first_name: "Edna",
          surname: "Krabapple"
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
          alternative_idv_claimant_email: "claimant-2@example.com",
          alternative_idv_claimant_bank_details_match: false
        )
      end

      scenario "admin chooses no for one of the questions" do
        visit admin_claim_path(claim)
        click_on "View tasks"

        expect(task_status("One Login identity check")).to eql "No data"
        expect(task_status("Alternative verification")).to eql "Incomplete"
        click_link "Confirm the provider has verified the claimant’s identity"

        expect(page).to have_text(
          "The provider told us that they employ Edna Krabapple"
        )

        within_fieldset(
          "Do the personal details provided by the claimant match the details " \
          "from the provider?"
        ) do
          choose "Yes"
        end

        expect(page).to have_text(
          "The provider told us that they do not recognise the bank account " \
          "details that Edna Krabapple submitted."
        )

        within_fieldset(
          "Has Edna Krabapple provided their own bank account details?"
        ) do
          choose "No"
        end

        click_button "Save and continue"

        visit admin_claim_tasks_path(claim)

        expect(task_status("Alternative verification")).to eq "Failed"
      end
    end

    context "when visiting a completed task" do
      let(:claim) do
        create(
          :claim,
          :submitted,
          :with_failed_ol_idv,
          policy: Policies::EarlyYearsPayments,
          eligibility:,
          date_of_birth: Date.new(1970, 1, 1),
          postcode: "ec1n 2td",
          national_insurance_number: "ab123456c",
          email_address: "claimant@example.com",
          first_name: "Edna",
          surname: "Krabapple"
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
          alternative_idv_claimant_email: "claimant-2@example.com",
          alternative_idv_claimant_bank_details_match: false
        )
      end

      scenario "admin chooses no for one of the questions" do
        create(
          :task,
          :failed,
          name: "ey_alternative_verification",
          claim: claim,
          data: {
            "personal_details_match" => true,
            "bank_details_match" => false
          }
        )

        visit admin_claim_path(claim)
        click_on "View tasks"

        expect(task_status("One Login identity check")).to eq "No data"
        expect(task_status("Alternative verification")).to eq "Failed"
        click_link "Confirm the provider has verified the claimant’s identity"

        expect(page).to have_content(
          "Do the personal details provided by the claimant match the details " \
          "from the provider? Yes"
        )

        expect(page).to have_content(
          "Has Edna Krabapple provided their own bank account details? No"
        )

        # expect there to be no radio buttons and no submit button
        expect(page).not_to have_selector("input[type=radio]")
        expect(page).not_to have_button("Save and continue")
      end
    end
  end
end
