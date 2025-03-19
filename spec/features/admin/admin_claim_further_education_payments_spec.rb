require "rails_helper"

RSpec.feature "Admin claim further education payments" do
  around do |example|
    travel_to DateTime.new(AcademicYear.current.start_year, 9, 9, 10, 0, 0) do
      example.run
    end
  end

  before do
    create(:journey_configuration, :further_education_payments_provider)
    sign_in_as_service_operator
  end

  describe "Tasks" do
    describe "provider verification task" do
      context "when the provider is yet to verify the claim" do
        context "when a verification email has not been sent" do
          it "allows the admins to send the email" do
            fe_provider = create(
              :school,
              :further_education,
              :fe_eligible,
              name: "Springfield A and M"
            )

            claim = create(
              :claim,
              first_name: "Edna",
              surname: "Krabappel",
              email_address: "edna.krabappel@springfield-elementary.edu",
              date_of_birth: Date.new(1945, 7, 3),
              reference: "AB123456",
              created_at: DateTime.new(2024, 8, 1, 9, 0, 0),
              submitted_at: DateTime.new(2024, 8, 1, 9, 0, 0)
            )

            create(
              :further_education_payments_eligibility,
              contract_type: "fixed_term",
              claim: claim,
              school: fe_provider,
              award_amount: 1500,
              flagged_as_duplicate: true
            )

            visit admin_claim_path(claim)

            click_on "View tasks"

            click_on(
              "Confirm the provider has responded and verified the claimant’s " \
              "information"
            )

            expect(claim.eligibility.reload.provider_verification_email_last_sent_at).to be_nil

            expect(page).to have_content(
              "This task has not been sent to the provider yet."
            )

            perform_enqueued_jobs do
              click_on "Send provider verification request"
            end

            expect(page).to have_content(
              "The verification request was sent to the provider by " \
              "Aaron Admin on 9 September 2024 11:00am"
            )

            provider_email_address = claim.school.eligible_fe_provider.primary_key_contact_email_address

            expect(provider_email_address).to(
              have_received_email(
                "9a25fe46-2ee4-4a5c-8d47-0f04f058a87d",
                recipient_name: "Springfield A and M",
                claimant_name: "Edna Krabappel",
                claim_reference: "AB123456",
                claim_submission_date: "1 August 2024",
                verification_due_date: "15 August 2024",
                verification_url: Journeys::FurtherEducationPayments::Provider::SlugSequence.verify_claim_url(claim)
              )
            )

            expect(claim.eligibility.reload.provider_verification_email_last_sent_at).to eq Time.now
          end
        end

        context "when a verification email has been sent" do
          context "when the verification email was resent by the admin team" do
            it "shows who last sent the email" do
              fe_provider = create(
                :school,
                :further_education,
                :fe_eligible,
                name: "Springfield A and M"
              )

              claim = create(
                :claim,
                first_name: "Edna",
                surname: "Krabappel",
                email_address: "edna.krabappel@springfield-elementary.edu",
                date_of_birth: Date.new(1945, 7, 3),
                reference: "AB123456",
                created_at: DateTime.new(2024, 8, 1, 9, 0, 0),
                submitted_at: DateTime.new(2024, 8, 1, 9, 0, 0)
              )

              create(
                :further_education_payments_eligibility,
                contract_type: "fixed_term",
                claim: claim,
                school: fe_provider,
                award_amount: 1500,
                provider_verification_email_last_sent_at: DateTime.new(2024, 8, 1, 9, 0, 0)
              )

              create(
                :note,
                claim: claim,
                label: "provider_verification",
                created_by: create(
                  :dfe_signin_user,
                  given_name: "Some",
                  family_name: "Admin"
                )
              )

              visit admin_claim_path(claim)

              click_on "View tasks"

              click_on(
                "Confirm the provider has responded and verified the claimant’s " \
                "information"
              )

              expect(page).not_to have_content(
                "This task has not been sent to the provider yet."
              )

              expect(page).to have_content(
                "The verification request was sent to the provider by " \
                "Some Admin on 9 September 2024 11:00am"
              )

              perform_enqueued_jobs do
                click_on "Resend provider verification request"
              end

              provider_email_address = claim.school.eligible_fe_provider.primary_key_contact_email_address

              expect(provider_email_address).to(
                have_received_email(
                  "9a25fe46-2ee4-4a5c-8d47-0f04f058a87d",
                  recipient_name: "Springfield A and M",
                  claimant_name: "Edna Krabappel",
                  claim_reference: "AB123456",
                  claim_submission_date: "1 August 2024",
                  verification_due_date: "15 August 2024",
                  verification_url: Journeys::FurtherEducationPayments::Provider::SlugSequence.verify_claim_url(claim)
                )
              )

              expect(claim.eligibility.reload.provider_verification_email_last_sent_at).to eq Time.now
            end
          end

          context "when the verification email was sent when the claim was submitted" do
            it "allows the admin to resend the email" do
              fe_provider = create(
                :school,
                :further_education,
                :fe_eligible,
                name: "Springfield A and M"
              )

              claim = create(
                :claim,
                first_name: "Edna",
                surname: "Krabappel",
                email_address: "edna.krabappel@springfield-elementary.edu",
                date_of_birth: Date.new(1945, 7, 3),
                reference: "AB123456",
                created_at: DateTime.new(2024, 8, 1, 9, 0, 0),
                submitted_at: DateTime.new(2024, 8, 1, 9, 0, 0)
              )

              create(
                :further_education_payments_eligibility,
                contract_type: "fixed_term",
                claim: claim,
                school: fe_provider,
                award_amount: 1500,
                provider_verification_email_last_sent_at: DateTime.new(2024, 8, 1, 9, 0, 0)
              )

              visit admin_claim_path(claim)

              click_on "View tasks"

              click_on(
                "Confirm the provider has responded and verified the claimant’s " \
                "information"
              )

              expect(page).not_to have_content(
                "This task has not been sent to the provider yet."
              )

              expect(page).not_to have_content(
                "The verification request was sent to the provider by "
              )

              perform_enqueued_jobs do
                click_on "Resend provider verification request"
              end

              # This is the user we're logged in as
              expect(page).to have_content(
                "The verification request was sent to the provider by " \
                "Aaron Admin on 9 September 2024 11:00am"
              )

              provider_email_address = claim.school.eligible_fe_provider.primary_key_contact_email_address

              expect(provider_email_address).to(
                have_received_email(
                  "9a25fe46-2ee4-4a5c-8d47-0f04f058a87d",
                  recipient_name: "Springfield A and M",
                  claimant_name: "Edna Krabappel",
                  claim_reference: "AB123456",
                  claim_submission_date: "1 August 2024",
                  verification_due_date: "15 August 2024",
                  verification_url: Journeys::FurtherEducationPayments::Provider::SlugSequence.verify_claim_url(claim)
                )
              )

              expect(claim.eligibility.reload.provider_verification_email_last_sent_at).to eq Time.now
            end

            it "shows the chaser verification email was sent if one was sent after 2 weeks" do
              fe_provider = create(
                :school,
                :further_education,
                :fe_eligible,
                name: "Springfield A and M"
              )

              claim = create(
                :claim,
                first_name: "Edna",
                surname: "Krabappel",
                email_address: "edna.krabappel@springfield-elementary.edu",
                date_of_birth: Date.new(1945, 7, 3),
                reference: "AB123456",
                created_at: DateTime.new(2024, 8, 1, 9, 0, 0),
                submitted_at: DateTime.new(2024, 8, 1, 9, 0, 0)
              )

              create(
                :further_education_payments_eligibility,
                contract_type: "fixed_term",
                claim: claim,
                school: fe_provider,
                award_amount: 1500,
                provider_verification_email_last_sent_at: DateTime.new(2024, 8, 1, 9, 0, 0),
                provider_verification_email_count: 1
              )

              perform_enqueued_jobs do
                FurtherEducationPayments::ProviderVerificationChaseEmailJob.perform_now
              end

              visit admin_claim_path(claim)

              click_on "View tasks"

              click_on(
                "Confirm the provider has responded and verified the claimant’s " \
                "information"
              )

              expect(page).to have_content(
                "The verification request was sent to the provider by " \
                "an automated process on 9 September 2024 11:00am"
              )
            end
          end
        end
      end

      context "when the provider has verified the claim" do
        context "when the claim is for a fixed term contract" do
          it "shows the verification information and allows the admin to complete the task" do
            fe_provider = create(:school, :further_education, name: "Springfield A and M")

            claim = create(
              :claim,
              first_name: "Edna",
              surname: "Krabappel",
              email_address: "edna.krabappel@springfield-elementary.edu",
              date_of_birth: Date.new(1945, 7, 3),
              reference: "AB123456",
              created_at: DateTime.new(2024, 8, 1, 9, 0, 0),
              submitted_at: DateTime.new(2024, 8, 1, 9, 0, 0)
            )

            create(
              :further_education_payments_eligibility,
              :verified,
              contract_type: "fixed_term",
              claim: claim,
              school: fe_provider,
              award_amount: 1500
            )

            visit admin_claim_path(claim)

            click_on "View tasks"

            click_on(
              "Confirm the provider has responded and verified the claimant’s " \
              "information"
            )

            expect(page).to have_content(
              "This task was verified by the provider (Seymoure Skinner)"
            )

            within_table_row("Contract of employment") do |claimant, provider|
              expect(claimant).to have_text("Fixed term")
              expect(provider).to have_text("Yes")
            end

            within_table_row("Teaching responsibilities") do |claimant, provider|
              expect(claimant).to have_text("Yes")
              expect(provider).to have_text("Yes")
            end

            within_table_row("First 5 years of teaching") do |claimant, provider|
              expect(claimant).to have_text "September 2023 to August 2024"
              expect(provider).to have_text "Yes"
            end

            within_table_row("Timetabled teaching hours") do |claimant, provider|
              expect(claimant).to have_text("12 hours or more per week")
              expect(provider).to have_text("Yes")
            end

            within_table_row("Age range taught") do |claimant, provider|
              expect(claimant).to have_text("Yes")
              expect(provider).to have_text("No")
            end

            within_table_row("Subject") do |claimant, provider|
              expect(claimant).to have_text("Maths")
              expect(claimant).to have_text("Physics")
              expect(provider).to have_text("No")
            end

            within_table_row("Course") do |claimant, provider|
              expect(claimant).to have_content(
                "Qualifications approved for funding at level 3 and below in " \
                "the mathematics and statistics (opens in new tab) sector subject area" \
                "GCSE in maths, functional skills qualifications and other " \
                "maths qualifications (opens in new tab) approved for teaching " \
                "to 16 to 19-year-olds who meet the condition of funding" \
                "GCSE physics"
              )

              expect(provider).to have_text("No")
            end

            within_fieldset("Has the provider confirmed the claimant's details?") do
              choose "Yes"
            end

            click_on "Save and continue"

            visit admin_claim_tasks_path(claim)

            expect(task_status("Provider verification")).to eq "Passed"
          end
        end

        context "when the claim is for a varible hours contract" do
          it "shows the verification information and allows the admin to complete the task" do
            fe_provider = create(:school, :further_education, name: "Springfield A and M")

            claim = create(
              :claim,
              first_name: "Edna",
              surname: "Krabappel",
              email_address: "edna.krabappel@springfield-elementary.edu",
              date_of_birth: Date.new(1945, 7, 3),
              reference: "AB123456",
              created_at: DateTime.new(2024, 8, 1, 9, 0, 0),
              submitted_at: DateTime.new(2024, 8, 1, 9, 0, 0)
            )

            create(
              :further_education_payments_eligibility,
              :verified_variable_hours,
              claim: claim,
              school: fe_provider,
              award_amount: 1500
            )

            visit admin_claim_path(claim)

            click_on "View tasks"

            click_on(
              "Confirm the provider has responded and verified the claimant’s " \
              "information"
            )

            expect(page).to have_content(
              "This task was verified by the provider (Seymoure Skinner)"
            )

            within_table_row("Contract of employment") do |claimant, provider|
              expect(claimant).to have_text("Variable hours")
              expect(provider).to have_text("Yes")
            end

            within_table_row("Teaching responsibilities") do |claimant, provider|
              expect(claimant).to have_text("Yes")
              expect(provider).to have_text("Yes")
            end

            within_table_row("First 5 years of teaching") do |claimant, provider|
              expect(claimant).to have_text "September 2023 to August 2024"
              expect(provider).to have_text "Yes"
            end

            within_table_row("Taught at least one term") do |claimant, provider|
              expect(claimant).to have_text("Yes")
              expect(provider).to have_text("Yes")
            end

            within_table_row("Timetabled teaching hours") do |claimant, provider|
              expect(claimant).to have_text("12 hours or more per week")
              expect(provider).to have_text("Yes")
            end

            within_table_row("Age range taught") do |claimant, provider|
              expect(claimant).to have_text("Yes")
              expect(provider).to have_text("Yes")
            end

            within_table_row("Subject") do |claimant, provider|
              expect(claimant).to have_text("Maths")
              expect(claimant).to have_text("Physics")
              expect(provider).to have_text("Yes")
            end

            within_table_row("Course") do |claimant, provider|
              expect(claimant).to have_content(
                "Qualifications approved for funding at level 3 and below in " \
                "the mathematics and statistics (opens in new tab) sector subject area" \
                "GCSE in maths, functional skills qualifications and other " \
                "maths qualifications (opens in new tab) approved for teaching " \
                "to 16 to 19-year-olds who meet the condition of funding" \
                "GCSE physics"
              )

              expect(provider).to have_text("Yes")
            end

            within_table_row("Timetabled teaching hours next term") do |claimant, provider|
              expect(claimant).to have_text("At least 2.5 hours per week")
              expect(provider).to have_text("No")
            end

            within_fieldset("Has the provider confirmed the claimant's details?") do
              choose "No"
            end

            click_on "Save and continue"

            visit admin_claim_tasks_path(claim)

            expect(task_status("Provider verification")).to eq "Failed"
          end
        end
      end
    end
  end

  def within_table_row(label, &block)
    within(first("tr", text: label)) do
      claimant_answer = find("td:first-of-type")
      provider_answer = find("td:last-of-type")

      yield(claimant_answer, provider_answer)
    end
  end

  def task_status(task_name)
    find(
      :xpath,
      "//h2[contains(@class, 'app-task-list__section') and contains(., '#{task_name}')]/following-sibling::ul//strong[contains(@class, 'govuk-tag')]"
    ).text
  end
end
