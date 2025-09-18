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

    context "when awaiting provider response" do
      it "shows the correct status and next steps" do
        visit admin_claim_path(claim)
        click_on "View tasks"

        expect(task_status("One Login identity check")).to eql "No data"
        expect(task_status("Alternative verification")).to eql "Incomplete"
        click_link "Confirm the provider has verified the claimant’s identity"

        expect(page).to have_text "Awaiting provider response"
        expect(page).to have_text "Do the personal details provided by the claimant match the details from the provider?"
      end
    end

    context "when provider has responded" do
      let(:claim) do
        create(
          :claim,
          :submitted,
          :with_failed_ol_idv,
          policy: Policies::EarlyYearsPayments,
          eligibility: eligibility,
          date_of_birth: Date.new(1970, 1, 1),
          postcode: "ec1n 2td",
          national_insurance_number: "ab123456c",
          email_address: "claimant@example.com",
          first_name: "Edna",
          surname: "Krabappel",
          banking_name: "Edna Krabappel",
          hmrc_bank_validation_responses: hmrc_bank_validation_responses
        )
      end

      let(:hmrc_bank_validation_responses) do
        [
          {
            "body" => {
              "nameMatches" => "yes"
            }
          }
        ]
      end

      before do
        perform_enqueued_jobs do
          Policies::EarlyYearsPayments.alternative_idv_completed!(claim)
        end
      end

      context "when provider says claimant is not employed by them" do
        let(:eligibility) do
          create(
            :early_years_payments_eligibility,
            :with_eligible_ey_provider,
            :provider_claim_submitted,
            alternative_idv_claimant_employed_by_nursery: false,
            alternative_idv_claimant_date_of_birth: nil,
            alternative_idv_claimant_postcode: nil,
            alternative_idv_claimant_national_insurance_number: nil,
            alternative_idv_claimant_bank_details_match: nil,
            alternative_idv_claimant_email: nil,
            alternative_idv_claimant_employment_check_declaration: nil,
            alternative_idv_completed_at: 2.days.ago
          )
        end

        it "fails the task" do
          visit admin_claim_path(claim)
          click_on "View tasks"

          expect(task_status("One Login identity check")).to eql "No data"
          expect(task_status("Alternative verification")).to eql "Failed"
          click_link "Confirm the provider has verified the claimant’s identity"

          within "#personal-details" do
            expect(page).to have_content(
              "The provider told us that they do not employ Edna Krabappel."
            )

            expect(table_row("Date of birth")).to eq([
              "1 January 1970",
              "N/A"
            ])

            expect(table_row("Postcode")).to eq([
              "ec1n 2td",
              "N/A"
            ])

            expect(table_row("National Insurance number")).to eq([
              "AB123456C",
              "N/A"
            ])

            expect(table_row("Email")).to eq([
              "claimant@example.com",
              "N/A"
            ])
          end

          within "#bank-details" do
            expect(page).to have_content("Not applicable")

            expect(table_row("Edna Krabappel")).to eq([
              "Edna Krabappel", # Claimant's name
              "yes" # From HMRC response
            ])
          end

          within "#task-outcome" do
            expect(page).to have_content("Failed")
            expect(page).to have_content(
              "This task was performed by an automated check"
            )
          end
        end
      end

      context "when provider and claimant personal details match" do
        # Set some hmrc response so we don't auto pass the bank details check
        let(:hmrc_bank_validation_responses) do
          [
            {
              "body" => {
                "nameMatches" => "partial"
              }
            }
          ]
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
            alternative_idv_claimant_email: "CLAIMANT@example.com",
            alternative_idv_claimant_employment_check_declaration: true,
            alternative_idv_completed_at: 2.days.ago
          )
        end

        it "requires the admin to complete only the bank details section" do
          visit admin_claim_path(claim)
          click_on "View tasks"

          expect(task_status("One Login identity check")).to eql "No data"
          expect(task_status("Alternative verification")).to eql "Incomplete"
          click_link "Confirm the provider has verified the claimant’s identity"

          within "#personal-details" do
            expect(page).to have_content(
              "The provider told us that they employ Edna Krabappel."
            )

            expect(table_row("Date of birth")).to eq([
              "1 January 1970",
              "1 January 1970"
            ])

            expect(table_row("Postcode")).to eq([
              "ec1n 2td",
              "EC1N 2TD"
            ])

            expect(table_row("National Insurance number")).to eq([
              "AB123456C",
              "AB123456C"
            ])

            expect(table_row("Email")).to eq([
              "claimant@example.com",
              "CLAIMANT@example.com"
            ])

            # Expect no radio button
            expect(page).not_to have_selector("input[type=radio]")
          end

          within "#bank-details" do
            expect(page).to have_content(
              "The provider told us that they recognise the bank account details that Edna Krabappel submitted."
            )

            expect(table_row("Edna Krabappel")).to eq([
              "Edna Krabappel", # Claimant's name
              "partial" # From HMRC response
            ])

            within_fieldset(
              "Has Edna Krabappel provided their own bank account details?"
            ) do
              choose "Yes"
            end
          end

          click_button "Save and continue"

          visit admin_claim_path(claim)
          click_on "View tasks"
          expect(task_status("Alternative verification")).to eql "Passed"
          click_link "Confirm the provider has verified the claimant’s identity"

          within "#task-outcome" do
            expect(page).to have_content("Passed")
            expect(page).to have_content("This task was performed by Aaron Admin")
          end
        end
      end

      context "when the provider and claimant personal details do not match" do
        let(:eligibility) do
          create(
            :early_years_payments_eligibility,
            :with_eligible_ey_provider,
            :provider_claim_submitted,
            alternative_idv_claimant_employed_by_nursery: true,
            alternative_idv_claimant_date_of_birth: Date.new(1970, 1, 1),
            alternative_idv_claimant_postcode: "TE57 1NG",
            alternative_idv_claimant_national_insurance_number: "AB123456C",
            alternative_idv_claimant_bank_details_match: true,
            alternative_idv_claimant_email: "CLAIMANT@example.com",
            alternative_idv_claimant_employment_check_declaration: true,
            alternative_idv_completed_at: 2.days.ago
          )
        end

        it "allows the admin to make a decision" do
          visit admin_claim_path(claim)
          click_on "View tasks"

          expect(task_status("One Login identity check")).to eql "No data"
          expect(task_status("Alternative verification")).to eql "Incomplete"
          click_link "Confirm the provider has verified the claimant’s identity"

          # Try submitting without selecting an option for personal details
          click_button "Save and continue"

          expect(page).to have_content("You must select ‘Yes’ or ‘No’")

          within_fieldset(
            "Do the personal details provided by the claimant match the details from the provider?"
          ) do
            choose "Yes"
          end

          click_button "Save and continue"

          visit admin_claim_path(claim)
          click_on "View tasks"
          expect(task_status("Alternative verification")).to eql "Passed"
          click_link "Confirm the provider has verified the claimant’s identity"

          within "#task-outcome" do
            expect(page).to have_content("Passed")
            expect(page).to have_content("This task was performed by Aaron Admin")
          end
        end
      end

      context "when the provider says the bank details do not match" do
        let(:eligibility) do
          create(
            :early_years_payments_eligibility,
            :with_eligible_ey_provider,
            :provider_claim_submitted,
            alternative_idv_claimant_employed_by_nursery: true,
            alternative_idv_claimant_date_of_birth: Date.new(1970, 1, 1),
            alternative_idv_claimant_postcode: "TE57 1NG",
            alternative_idv_claimant_national_insurance_number: "AB123456C",
            alternative_idv_claimant_bank_details_match: false,
            alternative_idv_claimant_email: "CLAIMANT@example.com",
            alternative_idv_claimant_employment_check_declaration: true,
            alternative_idv_completed_at: 2.days.ago
          )
        end

        it "fails the task" do
          visit admin_claim_path(claim)
          click_on "View tasks"

          expect(task_status("One Login identity check")).to eql "No data"
          expect(task_status("Alternative verification")).to eql "Failed"
          click_link "Confirm the provider has verified the claimant’s identity"

          expect(page).not_to have_selector("input[type=radio]")
          expect(page).not_to have_button("Save and continue")

          within "#personal-details" do
            expect(page).to have_content(
              "The provider told us that they employ Edna Krabappel."
            )

            expect(page).to have_content(
              "Do the personal details provided by the claimant match the details from the provider? N/A"
            )
          end

          within "#bank-details" do
            expect(page).to have_content(
              "The provider told us that they do not recognise the bank account details that Edna Krabappel submitted."
            )

            expect(page).to have_content(
              "Has Edna Krabappel provided their own bank account details? No"
            )
          end

          within "#task-outcome" do
            expect(page).to have_content("Failed")
            expect(page).to have_content("This task was performed by an automated check")
          end
        end
      end

      context "when the bank details match but the personal details do not" do
        let(:eligibility) do
          create(
            :early_years_payments_eligibility,
            :with_eligible_ey_provider,
            :provider_claim_submitted,
            alternative_idv_claimant_employed_by_nursery: true,
            alternative_idv_claimant_date_of_birth: Date.new(1970, 1, 1),
            alternative_idv_claimant_postcode: "TE57 1NG",
            alternative_idv_claimant_national_insurance_number: "AB123456C",
            alternative_idv_claimant_bank_details_match: true,
            alternative_idv_claimant_email: "CLAIMANT@example.com",
            alternative_idv_claimant_employment_check_declaration: true,
            alternative_idv_completed_at: 2.days.ago
          )
        end

        it "allows the admin to make a decision" do
          visit admin_claim_path(claim)
          click_on "View tasks"

          expect(task_status("One Login identity check")).to eql "No data"
          expect(task_status("Alternative verification")).to eql "Incomplete"
          click_link "Confirm the provider has verified the claimant’s identity"

          within "#bank-details" do
            expect(page).not_to have_selector("input[type=radio]")
          end

          # Attempt to submit without selecting an option for personal details
          click_button "Save and continue"

          expect(page).to have_content("You must select ‘Yes’ or ‘No’")

          within_fieldset(
            "Do the personal details provided by the claimant match the details from the provider?"
          ) do
            choose "Yes"
          end

          click_button "Save and continue"

          visit admin_claim_path(claim)
          click_on "View tasks"
          expect(task_status("Alternative verification")).to eql "Passed"
          click_link "Confirm the provider has verified the claimant’s identity"
        end
      end

      context "when personal details and bank details match" do
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
            alternative_idv_claimant_email: "CLAIMANT@example.com",
            alternative_idv_claimant_employment_check_declaration: true,
            alternative_idv_completed_at: 2.days.ago
          )
        end

        it "passes the task automatically" do
          visit admin_claim_path(claim)
          click_on "View tasks"

          expect(task_status("Alternative verification")).to eql "Passed"
          click_link "Confirm the provider has verified the claimant’s identity"

          within "#task-outcome" do
            expect(page).to have_content("Passed")
            expect(page).to have_content(
              "This task was performed by an automated check"
            )
          end
        end
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
          surname: "Krabappel"
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
          "Has Edna Krabappel provided their own bank account details? No"
        )

        # expect there to be no radio buttons and no submit button
        expect(page).not_to have_selector("input[type=radio]")
        expect(page).not_to have_button("Save and continue")
      end
    end
  end

  def table_row(first_column_text)
    find("tr", text: first_column_text).all("td").map(&:text)
  end
end
