require "rails_helper"

RSpec.feature "Admin claim further education payments" do
  around do |example|
    travel_to DateTime.new(AcademicYear.current.start_year, 9, 9, 10, 0, 0) do
      example.run
    end
  end

  before do
    FeatureFlag.create!(name: :fe_provider_identity_verification, enabled: true)
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

    describe "provider identity verification task" do
      context "when the claimant has failed IDV" do
        context "when the provider hasn't verified the claim" do
          it "shows the alternative idv task" do
            claim = create(
              :claim,
              :submitted,
              policy: Policies::FurtherEducationPayments,
              onelogin_idv_at: 1.day.ago,
              identity_confirmed_with_onelogin: false
            )

            create(
              :further_education_payments_eligibility,
              claim: claim,
              provider_verification_email_last_sent_at: DateTime.new(2025, 3, 1, 9, 0, 0),
              provider_verification_email_count: 1
            )

            visit admin_claim_tasks_path(claim)

            expect(page).to have_content("Alternative identity verification")

            click_on "Confirm the provider has verified the claimant's identity"

            expect(page).to have_content(
              "Resend provider verification request"
            )
          end

          it "shows the option to send the verificaiton email for duplicates" do
            claim = create(
              :claim,
              :submitted,
              policy: Policies::FurtherEducationPayments,
              onelogin_idv_at: 1.day.ago,
              identity_confirmed_with_onelogin: false
            )

            fe_provider = create(
              :school,
              :further_education,
              :fe_eligible,
              name: "Springfield A and M"
            )

            create(
              :further_education_payments_eligibility,
              claim: claim,
              school: fe_provider,
              flagged_as_duplicate: true
            )

            visit admin_claim_tasks_path(claim)

            expect(page).to have_content("Alternative identity verification")

            click_on "Confirm the provider has verified the claimant's identity"

            expect(page).to have_content(
              "This task has not been sent to the provider yet."
            )

            expect(page).not_to have_content(
              "The verification request was sent to the provider"
            )

            perform_enqueued_jobs do
              click_on "Send provider verification request"
            end

            expect(page).to have_content(
              "The verification request was sent to the provider by " \
              "Aaron Admin on 9 September #{AcademicYear.current.start_year} " \
              "11:00am"
            )

            provider_email_address = fe_provider.eligible_fe_provider.primary_key_contact_email_address

            expect(provider_email_address).to(
              have_received_email("9a25fe46-2ee4-4a5c-8d47-0f04f058a87d")
            )
          end
        end

        context "when the provider has verified the claim" do
          it "shows the provider and claimant entered details" do
            claim = create(
              :claim,
              :submitted,
              policy: Policies::FurtherEducationPayments,
              onelogin_idv_at: 1.day.ago,
              identity_confirmed_with_onelogin: false,
              national_insurance_number: "QQ123456B",
              postcode: "TE57 2NG",
              date_of_birth: Date.new(1990, 2, 1)
            )

            create(
              :further_education_payments_eligibility,
              claim: claim,
              flagged_as_duplicate: true,
              claimant_date_of_birth: Date.new(1990, 1, 1),
              claimant_postcode: "TE57 1NG",
              claimant_national_insurance_number: "QQ123456C",
              claimant_valid_passport: true,
              claimant_passport_number: "123456789",
              claimant_identity_verified_at: DateTime.now,
              valid_passport: true,
              passport_number: "123456780"
            )

            AutomatedChecks::ClaimVerifiers::AlternativeIdentityVerification
              .new(claim: claim).perform

            visit admin_claim_tasks_path(claim)

            click_on "Confirm the provider has verified the claimant's identity"

            within_table_row("National Insurance number") do |claimant, provider|
              expect(claimant).to have_text("QQ123456B")
              expect(provider).to have_text("QQ123456C")
            end

            within_table_row("Post code") do |claimant, provider|
              expect(claimant).to have_text("TE57 2NG")
              expect(provider).to have_text("TE57 1NG")
            end

            within_table_row("Date of Birth") do |claimant, provider|
              expect(claimant).to have_text("1 February 1990")
              expect(provider).to have_text("1 January 1990")
            end

            within_table_row("Passport number") do |claimant, provider|
              expect(claimant).to have_text("123456780")
              expect(provider).to have_text("123456789")
            end
          end

          context "when the provider and claimant details match" do
            it "shows the task as passed" do
              claim = create(
                :claim,
                :submitted,
                policy: Policies::FurtherEducationPayments,
                onelogin_idv_at: 1.day.ago,
                identity_confirmed_with_onelogin: false,
                national_insurance_number: "QQ123456C",
                postcode: "TE57 1NG",
                date_of_birth: Date.new(1990, 1, 1)
              )

              create(
                :further_education_payments_eligibility,
                claim: claim,
                flagged_as_duplicate: true,
                claimant_date_of_birth: Date.new(1990, 1, 1),
                claimant_postcode: "TE57 1NG",
                claimant_national_insurance_number: "QQ123456C",
                claimant_valid_passport: true,
                claimant_passport_number: "123456789",
                claimant_identity_verified_at: DateTime.now,
                valid_passport: true,
                passport_number: "123456789",
                verification: {
                  verifier: {
                    dfe_sign_in_uid: "123",
                    first_name: "Seymour",
                    last_name: "Skinner",
                    email: "seymore.skinner@springfield-elementary.edu",
                    dfe_sign_in_organisation_name: "Springfield Elementary",
                    dfe_sign_in_role_codes: ["teacher_payments_claim_verifier"]
                  }
                }
              )

              AutomatedChecks::ClaimVerifiers::AlternativeIdentityVerification
                .new(claim: claim).perform

              visit admin_claim_tasks_path(claim)

              expect(
                task_status("Alternative identity verification")
              ).to eq("Passed")

              click_on(
                "Confirm the provider has verified the claimant's identity"
              )

              expect(page).not_to have_content(
                "Do the details entered by the claimant match the personal " \
                "details entered by the provider?"
              )

              expect(find(".govuk-tag")).to have_text("Passed")

              expect(page).to have_content(
                "This task was performed by the provider (Seymour Skinner) on " \
                "9 September #{AcademicYear.current.start_year} 11:00am"
              )
            end
          end

          context "when the provider and claimant details don't match" do
            it "shows the task as no match and shows the manual approval form" do
              claim = create(
                :claim,
                :submitted,
                policy: Policies::FurtherEducationPayments,
                onelogin_idv_at: 1.day.ago,
                identity_confirmed_with_onelogin: false,
                national_insurance_number: "QQ123456B",
                postcode: "TE57 2NG",
                date_of_birth: Date.new(1990, 2, 1)
              )

              create(
                :further_education_payments_eligibility,
                claim: claim,
                flagged_as_duplicate: true,
                claimant_date_of_birth: Date.new(1990, 1, 1),
                claimant_postcode: "TE57 1NG",
                claimant_national_insurance_number: "QQ123456C",
                claimant_valid_passport: true,
                claimant_passport_number: "123456789",
                claimant_identity_verified_at: DateTime.now,
                valid_passport: false,
                passport_number: nil
              )

              AutomatedChecks::ClaimVerifiers::AlternativeIdentityVerification
                .new(claim: claim).perform

              visit admin_claim_tasks_path(claim)

              expect(
                task_status("Alternative identity verification")
              ).to eq("No match")

              click_on(
                "Confirm the provider has verified the claimant's identity"
              )

              expect(page).to have_content(
                "Do the details entered by the claimant match the personal " \
                "details entered by the provider?"
              )

              choose "No"

              click_on "Save and continue"

              visit admin_claim_tasks_path(claim)

              expect(
                task_status("Alternative identity verification")
              ).to eq("Failed")

              click_on(
                "Confirm the provider has verified the claimant's identity"
              )

              expect(page).not_to have_content(
                "Do the details entered by the claimant match the personal " \
                "details entered by the provider?"
              )

              expect(find(".govuk-tag")).to have_text("Failed")

              expect(page).to have_content(
                "This task was performed by Aaron Admin on 9 September " \
                "#{AcademicYear.current.start_year} 11:00am"
              )
            end
          end
        end
      end
    end

    describe "FE claim decisions" do
      context "when the claim is flagged for alternative idv" do
        context "when the alternative idv task has not been completed" do
          it "shows the admins a warning" do
            claim = create(
              :claim,
              :submitted,
              policy: Policies::FurtherEducationPayments,
              onelogin_idv_at: 1.day.ago,
              identity_confirmed_with_onelogin: false
            )

            visit new_admin_claim_decision_path(claim)

            task_warning = find(".govuk-error-summary:first-of-type")

            within(task_warning) do
              expect(page).to have_content(
                "Some tasks have not yet been completed"
              )

              expect(page).to have_content(
                "Confirm the provider has verified the claimant's identity"
              )
            end

            approve_button = find("#decision_approved_true")

            expect(approve_button).to be_disabled

            reject_button = find("#decision_approved_false")

            expect(reject_button).to be_disabled
          end
        end

        context "when the alternative idv task is a fail" do
          it "doesn't show a warning" do
            stub_const(
              "Policies::FurtherEducationPayments::REJECTED_MIN_QA_THRESHOLD",
              0
            )

            claim = create(
              :claim,
              :submitted,
              policy: Policies::FurtherEducationPayments,
              onelogin_idv_at: 1.day.ago,
              identity_confirmed_with_onelogin: false,
              email_address: "edna-krabappel@springfield-elementary.edu"
            )

            create(
              :task,
              :claim_verifier_context,
              claim: claim,
              name: "alternative_identity_verification",
              manual: true,
              passed: false,
              claim_verifier_match: "none"
            )

            visit new_admin_claim_decision_path(claim)

            task_warning = find(".govuk-error-summary:first-of-type")

            within(task_warning) do
              expect(page).not_to have_content(
                "Confirm the provider has verified the claimant's identity"
              )
            end

            approve_button = find("#decision_approved_true")

            expect(approve_button).not_to be_disabled

            reject_button = find("#decision_approved_false")

            expect(reject_button).not_to be_disabled

            choose "Reject"

            check "Provider-led identity check failed"

            perform_enqueued_jobs do
              click_on "Confirm decision"
            end

            expect("edna-krabappel@springfield-elementary.edu").to(
              have_received_email(
                "a1bb5f64-585f-4b03-b9db-0b20ad801b34",
                reason_alternative_identity_verification_check_failed: "yes"
              )
            )
          end
        end

        context "when the alternative idv task is a pass" do
          it "doesn't show a warning" do
            claim = create(
              :claim,
              :submitted,
              policy: Policies::FurtherEducationPayments,
              onelogin_idv_at: 1.day.ago,
              identity_confirmed_with_onelogin: false
            )

            create(
              :task,
              :claim_verifier_context,
              claim: claim,
              name: "alternative_identity_verification",
              manual: true,
              passed: true,
              claim_verifier_match: "none"
            )

            visit new_admin_claim_decision_path(claim)

            task_warning = find(".govuk-error-summary:first-of-type")

            within(task_warning) do
              expect(page).not_to have_content(
                "Confirm the provider has verified the claimant's identity"
              )
            end

            approve_button = find("#decision_approved_true")

            expect(approve_button).not_to be_disabled

            reject_button = find("#decision_approved_false")

            expect(reject_button).not_to be_disabled
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
