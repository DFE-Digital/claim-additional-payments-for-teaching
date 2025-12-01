require "rails_helper"

RSpec.feature "Admin claim further education payments" do
  around do |example|
    travel_to DateTime.new(AcademicYear.current.start_year, 9, 9, 10, 0, 0) do
      example.run
    end
  end

  before do
    sign_in_as_service_operator
  end

  describe "Tasks" do
    describe "provider verification task" do
      context "when the provider has verified the claim" do
        context "when the claim is for a fixed term contract" do
          it "shows the verification information and allows the admin to complete the task" do
            fe_provider = create(:school, :further_education, name: "Springfield A and M")

            eligibility = create(
              :further_education_payments_eligibility,
              :eligible,
              :year_one_verified,
              contract_type: "fixed_term",
              school: fe_provider,
              award_amount: 1500
            )

            claim = create(
              :claim,
              :further_education,
              eligibility:,
              first_name: "Edna",
              surname: "Krabappel",
              email_address: "edna.krabappel@springfield-elementary.edu",
              date_of_birth: Date.new(1945, 7, 3),
              reference: "AB123456",
              created_at: DateTime.new(2024, 8, 1, 9, 0, 0),
              submitted_at: DateTime.new(2024, 8, 1, 9, 0, 0),
              academic_year: AcademicYear.new("2024/2025")
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
              expect(claimant).to have_text("12 or more hours per week, but fewer than 20")
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

            eligibility = create(
              :further_education_payments_eligibility,
              :year_one_verified_variable_hours,
              school: fe_provider,
              award_amount: 1500
            )

            claim = create(
              :claim,
              :further_education,
              eligibility:,
              first_name: "Edna",
              surname: "Krabappel",
              email_address: "edna.krabappel@springfield-elementary.edu",
              date_of_birth: Date.new(1945, 7, 3),
              reference: "AB123456",
              created_at: DateTime.new(2024, 8, 1, 9, 0, 0),
              submitted_at: DateTime.new(2024, 8, 1, 9, 0, 0),
              academic_year: AcademicYear.new("2024/2025")
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
              expect(claimant).to have_text("12 or more hours per week, but fewer than 20")
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

            within_fieldset("Has the provider confirmed the claimant's details?") do
              choose "No"
            end

            click_on "Save and continue"

            visit admin_claim_tasks_path(claim)

            expect(task_status("Provider verification")).to eq "Failed"
          end
        end
      end

      context "when the provider has not yet verified the claim" do
        context "when the verification is overdue" do
          it "shows when the verification chaser email was last sent" do
            eligibility = create(
              :further_education_payments_eligibility,
              :eligible,
              provider_verification_chase_email_last_sent_at: 8.days.ago
            )

            claim = create(
              :claim,
              :further_education,
              :submitted,
              eligibility: eligibility,
              created_at: 3.weeks.ago
            )

            visit admin_claim_task_path(claim, "fe_provider_verification_v2")

            expect(page).to have_content(
              "A reminder to complete the provider verification check was " \
              "last sent on 1 September 2025 11:00am"
            )
          end

          it "has a button for ops to send another chaser email" do
            provider = create(:eligible_fe_provider, :with_school)

            eligibility = create(
              :further_education_payments_eligibility,
              :eligible,
              school: provider.school
            )

            claim = create(
              :claim,
              :further_education,
              :submitted,
              eligibility: eligibility,
              created_at: 3.weeks.ago
            )

            visit admin_claim_task_path(claim, "fe_provider_verification_v2")

            perform_enqueued_jobs do
              click_on "Send provider verification chaser email"
            end

            expect(page).to have_content(
              "Verification email sent to #{provider.school.name}"
            )

            expect(provider.primary_key_contact_email_address).to have_received_email(
              ApplicationMailer::FURTHER_EDUCATION_PAYMENTS[:PROVIDER_OVERDUE_VERIFICATION_CHASER_TEMPLATE_ID]
            )

            # view claim notes, expect to see note about chaser email being sent
            visit admin_claim_notes_path(claim)

            expect(page).to have_content(
              "Verification email sent to #{provider.school.name}\nby Aaron Admin"
            )
          end
        end

        context "when the verification is not overdue" do
          context "when the claim is less that 2 weeks old" do
            it "doesn't show send chaser email button" do
              provider = create(:eligible_fe_provider, :with_school)

              eligibility = create(
                :further_education_payments_eligibility,
                :eligible,
                school: provider.school
              )

              claim = create(
                :claim,
                :further_education,
                :submitted,
                eligibility: eligibility,
                created_at: 1.weeks.ago
              )

              visit admin_claim_task_path(claim, "fe_provider_verification_v2")

              expect(page).not_to have_content("Send chaser email")
            end
          end

          context "when the claim has already been verified" do
            it "doesn't show send chaser email button" do
              eligibility = create(
                :further_education_payments_eligibility,
                :eligible,
                :provider_verification_completed
              )

              claim = create(
                :claim,
                :further_education,
                :submitted,
                eligibility: eligibility,
                created_at: 3.weeks.ago
              )

              visit admin_claim_task_path(claim, "fe_provider_verification_v2")

              expect(page).not_to have_content("Send chaser email")
            end
          end
        end
      end
    end

    describe "provider identity verification task" do
      context "when the claimant has failed IDV" do
        context "when the provider hasn't verified the claim" do
          it "shows the alternative idv task" do
            claim = create(
              :claim,
              :submitted,
              policy: Policies::FurtherEducationPayments,
              onelogin_idv_at: 1.day.ago,
              identity_confirmed_with_onelogin: false,
              academic_year: AcademicYear.new("2025/2026")
            )

            create(
              :further_education_payments_eligibility,
              claim: claim,
              provider_verification_email_last_sent_at: DateTime.new(2025, 3, 1, 9, 0, 0),
              provider_verification_email_count: 1
            )

            visit admin_claim_tasks_path(claim)
            expect(page).to have_content("Alternative verification")
            click_on "Confirm the provider has verified the claimant’s identity"

            expect(page).to have_content(
              "Awaiting provider response"
            )
          end
        end

        context "when the provider has verified the claim" do
          it "shows the provider and claimant entered details" do
            claim = create(
              :claim,
              :submitted,
              first_name: "Edna",
              surname: "Krabappel",
              policy: Policies::FurtherEducationPayments,
              onelogin_idv_at: 1.day.ago,
              identity_confirmed_with_onelogin: false,
              national_insurance_number: "AB123456B",
              postcode: "TE57 2NG",
              date_of_birth: Date.new(1990, 2, 1),
              academic_year: AcademicYear.new("2025/2026"),
              email_address: "claimant@example.com",
              banking_name: "Edna Krabappel - banking name"
            )

            create(
              :further_education_payments_eligibility,
              claim: claim,
              flagged_as_duplicate: true,
              provider_verification_claimant_employed_by_college: true,
              provider_verification_claimant_date_of_birth: Date.new(1990, 1, 1),
              provider_verification_claimant_postcode: "TE57 1NG",
              provider_verification_claimant_national_insurance_number: "AB123456C",
              provider_verification_claimant_bank_details_match: true,
              provider_verification_claimant_email: "claimant@example.com"
            )

            AutomatedChecks::ClaimVerifiers::FeAlternativeVerification
              .new(claim: claim).perform

            visit admin_claim_tasks_path(claim)
            click_on "Confirm the provider has verified the claimant’s identity"

            expect(page).to have_content(
              "Do the personal details provided by the claimant match the " \
              "details from the provider?"
            )

            within_table_row("Date of birth") do |claimant, provider|
              expect(claimant).to have_text("1 February 1990")
              expect(provider).to have_text("1 January 1990")
            end

            within_table_row("Postcode") do |claimant, provider|
              expect(claimant).to have_text("TE57 2NG")
              expect(provider).to have_text("TE57 1NG")
            end

            within_table_row("National Insurance number") do |claimant, provider|
              expect(claimant).to have_text("AB123456B")
              expect(provider).to have_text("AB123456C")
            end

            within_table_row("Email") do |claimant, provider|
              expect(claimant).to have_text("claimant@example.com")
              expect(provider).to have_text("claimant@example.com")
            end

            expect(page).to have_content(
              "Has Edna Krabappel provided their own bank account details?"
            )

            within "#bank-details" do
              expect(page).to have_text("Edna Krabappel - banking name")
              expect(page).to have_text("Edna Krabappel")
              expect(page).to have_text("No value from HMRC")
            end
          end

          context "when the provider and claimant details match" do
            it "shows the task as passed" do
              claim = create(
                :claim,
                :submitted,
                policy: Policies::FurtherEducationPayments,
                first_name: "Edna",
                surname: "Krabappel",
                email_address: "claimant@example.com",
                onelogin_idv_at: 1.day.ago,
                identity_confirmed_with_onelogin: false,
                national_insurance_number: "AB123456B",
                postcode: "TE57 1NG",
                date_of_birth: Date.new(1990, 1, 1),
                academic_year: AcademicYear.new("2025/2026"),
                banking_name: "Edna Krabappel",
                hmrc_bank_validation_responses: [{"body" => {"nameMatches" => "yes"}}]
              )

              create(
                :further_education_payments_eligibility,
                claim: claim,
                work_email: "claimant@example.com",
                provider_verification_claimant_employed_by_college: true,
                provider_verification_claimant_date_of_birth: Date.new(1990, 1, 1),
                provider_verification_claimant_postcode: "TE57 1NG",
                provider_verification_claimant_national_insurance_number: "AB123456B",
                provider_verification_claimant_bank_details_match: true,
                provider_verification_claimant_email: "claimant@example.com"
              )

              perform_enqueued_jobs do
                Policies::FurtherEducationPayments.alternative_idv_completed!(claim)
              end

              visit admin_claim_tasks_path(claim)

              expect(
                task_status("Alternative verification")
              ).to eq("Passed")

              click_on(
                "Confirm the provider has verified the claimant’s identity"
              )

              expect(page).to have_content(
                "Do the personal details provided by the claimant match the " \
                "details from the provider? Yes"
              )

              expect(page).to have_content(
                "Has Edna Krabappel provided their own bank account details? Yes"
              )

              expect(find(".govuk-tag")).to have_text("Passed")

              expect(page).to have_content(
                "This task was performed by an automated check on 9 " \
                "September 2025 11:00am"
              )
            end
          end

          context "when the provider and claimant partially match" do
            it "shows the task with manual approval form" do
              claim = create(
                :claim,
                :submitted,
                policy: Policies::FurtherEducationPayments,
                first_name: "Edna",
                surname: "Krabappel",
                email_address: "claimant@example.com",
                onelogin_idv_at: 1.day.ago,
                identity_confirmed_with_onelogin: false,
                national_insurance_number: "AB123456B",
                postcode: "TE57 1NG",
                date_of_birth: Date.new(1990, 1, 1),
                academic_year: AcademicYear.new("2025/2026")
              )

              create(
                :further_education_payments_eligibility,
                claim: claim,
                flagged_as_duplicate: true,
                provider_verification_claimant_employed_by_college: true,
                provider_verification_claimant_date_of_birth: Date.new(1990, 1, 2),
                provider_verification_claimant_postcode: "TE57 1NG",
                provider_verification_claimant_national_insurance_number: "AB123456B",
                provider_verification_claimant_bank_details_match: true,
                provider_verification_claimant_email: "claimant@example.com"
              )

              perform_enqueued_jobs do
                Policies::FurtherEducationPayments.alternative_idv_completed!(claim)
              end

              visit admin_claim_tasks_path(claim)

              click_on(
                "Confirm the provider has verified the claimant’s identity"
              )

              within_fieldset(
                "Do the personal details provided by the claimant match the details from the provider?"
              ) { choose("Yes") }

              within_fieldset(
                "Has Edna Krabappel provided their own bank account details?"
              ) { choose("No") }

              click_on "Save and continue"

              visit admin_claim_tasks_path(claim)

              click_on(
                "Confirm the provider has verified the claimant’s identity"
              )

              expect(find(".govuk-tag")).to have_text("Failed")

              expect(page).to have_content(
                "This task was performed by Aaron Admin"
              )
            end
          end

          context "when the claimant does not work at establishment" do
            it "shows the task as failed" do
              claim = create(
                :claim,
                :submitted,
                policy: Policies::FurtherEducationPayments,
                email_address: "claimant@example.com",
                onelogin_idv_at: 1.day.ago,
                identity_confirmed_with_onelogin: false,
                national_insurance_number: "AB123456B",
                postcode: "TE57 1NG",
                date_of_birth: Date.new(1990, 1, 1),
                academic_year: AcademicYear.new("2025/2026")
              )

              create(
                :further_education_payments_eligibility,
                claim: claim,
                flagged_as_duplicate: true,
                provider_verification_claimant_employed_by_college: false
              )

              perform_enqueued_jobs do
                Policies::FurtherEducationPayments
                  .alternative_idv_completed!(claim)
              end

              visit admin_claim_tasks_path(claim)
              expect(
                task_status("Alternative verification")
              ).to eq("Failed")
              click_on(
                "Confirm the provider has verified the claimant’s identity"
              )

              expect(page).not_to have_content(
                "Do the details provided by the claimant match the " \
                "provider’s responses?"
              )
              expect(find(".govuk-tag")).to have_text("Failed")
              expect(page).to have_content(
                "This task was performed by an automated check on 9 " \
                "September 2025 11:00am"
              )
            end
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
end
