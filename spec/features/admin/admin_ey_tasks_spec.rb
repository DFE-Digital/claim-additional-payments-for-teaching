require "rails_helper"

RSpec.describe "Admin EY tasks" do
  around do |example|
    travel_to DateTime.new(2024, 11, 18, 9, 0, 0) do
      example.run
    end
  end

  describe "identity_confirmation" do
    context "when the practitioner hasn't completed their half of the claim" do
      it "shows that the task is unavailable" do
        claim = complete_provider_journey

        sign_in_as_service_operator

        visit admin_claim_tasks_path(claim)

        expect(task_status("Identity confirmation")).to eq("Incomplete")

        click_on "Confirm the claimant made the claim"

        expect(page).to have_content(
          "Provider entered claimant name Bobby Bobberson"
        )

        expect(page).to have_content(
          "This task is not available until the claimant has submitted their claim"
        )
      end
    end

    context "when the practitioner has completed their half of the claim" do
      context "when OL IDV is a pass and the names match" do
        it "passes the task" do
          claim = complete_provider_journey

          complete_practitioner_journey(
            claim: claim,
            date_of_birth: Date.new(1986, 1, 1),
            one_login_first_name: "Bobby",
            one_login_last_name: "Bobberson",
            one_login_date_of_birth: Date.new(1986, 1, 1)
          )

          sign_in_as_service_operator

          visit admin_claim_tasks_path(claim)

          expect(task_status("Identity confirmation")).to eq("Passed")

          click_on "Confirm the claimant made the claim"

          expect(page).to have_content(
            "Provider entered claimant name Bobby Bobberson"
          )

          expect(page).to have_content(
            "Claimant name from One Login Bobby Bobberson"
          )

          expect(page).to have_content(
            "Claimant entered DOB 1 January 1986"
          )

          expect(page).to have_content(
            "Claimant DOB from One Login 1 January 1986"
          )

          expect(page).to have_content(
            "This task was performed by GOV.UK One Login on " \
            "18 November 2024 9:00am"
          )
        end
      end

      context "when OL IDV is a pass and the names don't match" do
        context "when the names are a parital match" do
          let(:claim) { complete_provider_journey }

          before do
            complete_practitioner_journey(
              claim: claim,
              one_login_first_name: "Robby",
              one_login_last_name: "Bobberson",
              one_login_date_of_birth: Date.new(1986, 1, 1),
              date_of_birth: Date.new(1986, 1, 1)
            )

            sign_in_as_service_operator
          end

          it "shows the task as a partial match" do
            visit admin_claim_tasks_path(claim)

            expect(task_status("Identity confirmation")).to eq("Partial match")

            click_on "Confirm the claimant made the claim"

            expect(page).to have_content("Confirm claimant name")

            expect(page).to have_content(
              "Provider entered claimant name Bobby Bobberson"
            )

            expect(page).to have_content(
              "Claimant name from One Login Robby Bobberson"
            )

            expect(page).to have_content("Confirm claimant date of birth")

            expect(page).to have_content("Claimant entered DOB 1 January 1986")

            expect(page).to have_content(
              "Claimant DOB from One Login 1 January 1986"
            )

            expect(page).to have_content(
              "[GOV UK One Login] - Names partially match:"
            )

            expect(page).to have_content(
              'Provider-entered name: "Bobby Bobberson"'
            )

            expect(page).to have_content(
              'GOV.UK One Login Name: "Robby Bobberson"'
            )

            expect(page).to have_content('Claimant-entered DOB: "1 January 1986"')

            expect(page).to have_content('GOV.UK One Login DOB: "1 January 1986"')
          end

          it "allows the admin to mark the task as passed" do
            visit admin_claim_task_path(claim, name: "identity_confirmation")

            choose "Yes"

            click_on "Save and continue"

            visit admin_claim_task_path(claim, name: "identity_confirmation")

            expect(page).to have_content(
              "This task was performed by Aaron Admin"
            )

            visit admin_claim_tasks_path(claim)

            expect(task_status("Identity confirmation")).to eq("Passed")
          end

          it "allows the admin to mark the task as failed" do
            visit admin_claim_task_path(claim, name: "identity_confirmation")

            choose "No"

            click_on "Save and continue"

            visit admin_claim_task_path(claim, name: "identity_confirmation")

            expect(page).to have_content(
              "This task was performed by Aaron Admin"
            )

            visit admin_claim_tasks_path(claim)

            expect(task_status("Identity confirmation")).to eq("Failed")
          end
        end

        context "when the names don't match" do
          let(:claim) { complete_provider_journey }

          before do
            complete_practitioner_journey(
              claim: claim,
              one_login_first_name: "Robby",
              one_login_last_name: "Robberson",
              one_login_date_of_birth: Date.new(1986, 1, 1),
              date_of_birth: Date.new(1986, 1, 1)
            )

            sign_in_as_service_operator
          end

          it "shows the task as failed" do
            visit admin_claim_tasks_path(claim)

            expect(task_status("Identity confirmation")).to eq("Failed")

            click_on "Confirm the claimant made the claim"

            expect(page).to have_content("Confirm claimant name")

            expect(page).to have_content(
              "Provider entered claimant name Bobby Bobberson"
            )

            expect(page).to have_content(
              "Claimant name from One Login Robby Robberson"
            )

            expect(page).to have_content("Confirm claimant date of birth")

            expect(page).to have_content("Claimant entered DOB 1 January 1986")

            expect(page).to have_content(
              "Claimant DOB from One Login 1 January 1986"
            )

            expect(page).to have_content(
              "[GOV UK One Login] - Names do not match:"
            )

            expect(page).to have_content(
              'Provider-entered name: "Bobby Bobberson"'
            )

            expect(page).to have_content(
              'GOV.UK One Login Name: "Robby Robberson"'
            )

            expect(page).to have_content('Claimant-entered DOB: "1 January 1986"')

            expect(page).to have_content('GOV.UK One Login DOB: "1 January 1986"')
          end

          it "doesn't allow the admin to complete the task" do
            visit admin_claim_task_path(claim, name: "identity_confirmation")

            expect(page).not_to have_button("Save and continue")
          end
        end
      end

      context "when OL IDV is a fail" do
        it "fails the task" do
          claim = complete_provider_journey

          complete_practitioner_journey(
            claim: claim,
            one_login_first_name: "Bobby",
            one_login_last_name: "Bobberson",
            date_of_birth: Date.new(1986, 1, 11),
            one_login_date_of_birth: Date.new(1986, 1, 1)
          )

          sign_in_as_service_operator

          visit admin_claim_tasks_path(claim)

          expect(task_status("Identity confirmation")).to eq("Failed")

          click_on "Confirm the claimant made the claim"

          expect(page).to have_content(
            "[GOV UK One Login] - IDV mismatch:"
          )

          expect(page).to have_content(
            'Provider-entered name: "Bobby Bobberson"'
          )

          expect(page).to have_content(
            'GOV.UK One Login Name: "Bobby Bobberson"'
          )

          expect(page).to have_content('Claimant-entered DOB: "11 January 1986"')

          expect(page).to have_content('GOV.UK One Login DOB: "1 January 1986"')

          expect(page).not_to have_button("Save and continue")
        end
      end
    end
  end

  describe "employment_check" do
    context "when the practitioner hasn't completed their half of the claim" do
      it "shows that the task is unavailable" do
        claim = complete_provider_journey

        sign_in_as_service_operator

        visit admin_claim_tasks_path(claim)

        expect(task_status("Employment")).to eq("Incomplete")

        click_on "Check employment information"

        expect(page).to have_content(
          "This task will be available from 17 May 2025"
        )
      end
    end

    context "when the practitioner has completed their half of the claim" do
      context "when the employment task is available" do
        it "allows the admin to pass / fail the task" do
          claim = complete_provider_journey

          complete_practitioner_journey(
            claim: claim,
            one_login_first_name: "Robby",
            one_login_last_name: "Bobberson",
            one_login_date_of_birth: Date.new(1986, 1, 1),
            date_of_birth: Date.new(1986, 1, 1)
          )

          claim.eligibility.update!(
            start_date: Policies::EarlyYearsPayments::RETENTION_PERIOD.ago
          )

          sign_in_as_service_operator

          visit admin_claim_tasks_path(claim)

          expect(task_status("Employment")).to eq("Incomplete")

          click_on "Check employment information"

          choose "Yes"

          click_on "Save and continue"

          visit admin_claim_tasks_path(claim)

          expect(task_status("Employment")).to eq("Passed")
        end
      end
    end
  end

  describe "student_loan_plan" do
    context "when the practitioner hasn't completed their half of the claim" do
      it "shows that the task is unavailable" do
        claim = complete_provider_journey

        sign_in_as_service_operator

        visit admin_claim_tasks_path(claim)

        expect(task_status("Student loan plan")).to eq("Incomplete")

        click_on "Check student loan plan"

        expect(page).to have_content(
          "This task is not available until the claimant has submitted their claim"
        )
      end
    end

    context "when the practitioner has completed their half of the claim" do
      it "allows the admin to pass / fail the task" do
        claim = complete_provider_journey

        complete_practitioner_journey(
          claim: claim,
          one_login_first_name: "Robby",
          one_login_last_name: "Bobberson",
          one_login_date_of_birth: Date.new(1986, 1, 1),
          date_of_birth: Date.new(1986, 1, 1)
        )

        sign_in_as_service_operator

        visit admin_claim_tasks_path(claim)

        expect(task_status("Student loan plan")).to eq("Incomplete")

        click_on "Check student loan plan"

        expect(page).to have_content(
          "No matching entry has been found in the Student Loan Company data yet."
        )
      end
    end
  end

  describe "payroll_details" do
    context "when the practitioner hasn't completed their half of the claim" do
      it "shows that the task is unavailable" do
        claim = complete_provider_journey

        sign_in_as_service_operator

        visit admin_claim_tasks_path(claim)

        expect(task_status("Payroll details")).to eq("Incomplete")

        click_on "Check bank account details"

        expect(page).to have_content(
          "This task is not available until the claimant has submitted their claim"
        )
      end
    end

    context "when the practitioner has completed their half of the claim" do
      it "allows the admin to pass / fail the task" do
        claim = complete_provider_journey

        complete_practitioner_journey(
          claim: claim,
          one_login_first_name: "Robby",
          one_login_last_name: "Bobberson",
          one_login_date_of_birth: Date.new(1986, 1, 1),
          date_of_birth: Date.new(1986, 1, 1)
        )

        sign_in_as_service_operator

        visit admin_claim_tasks_path(claim)

        expect(task_status("Payroll details")).to eq("Incomplete")

        click_on "Check bank account details"

        choose "Yes"

        click_on "Save and continue"

        visit admin_claim_tasks_path(claim)

        expect(task_status("Payroll details")).to eq("Passed")
      end
    end
  end

  describe "payroll_gender" do
    context "when the practitioner hasn't completed their half of the claim" do
      it "shows that the task is unavailable" do
        claim = complete_provider_journey

        sign_in_as_service_operator

        visit admin_claim_tasks_path(claim)

        expect(task_status("Payroll gender")).to eq("Incomplete")

        click_on "How is the claimant’s gender recorded for payroll purposes?"

        expect(page).to have_content(
          "This task is not available until the claimant has submitted their claim"
        )
      end
    end

    context "when the practitioner has completed their half of the claim" do
      context "when payroll gender is missing" do
        it "allows the admin to pass / fail the task" do
          claim = complete_provider_journey

          complete_practitioner_journey(
            claim: claim,
            one_login_first_name: "Robby",
            one_login_last_name: "Bobberson",
            one_login_date_of_birth: Date.new(1986, 1, 1),
            date_of_birth: Date.new(1986, 1, 1),
            payroll_gender: "I don’t know"
          )

          sign_in_as_service_operator

          visit admin_claim_tasks_path(claim)

          expect(task_status("Payroll gender")).to eq("Incomplete")

          click_on "How is the claimant’s gender recorded for payroll purposes?"

          choose "Male"

          click_on "Save and continue"

          visit admin_claim_tasks_path(claim)

          expect(task_status("Payroll gender")).to eq("Passed")
        end
      end

      context "when payroll gender is present" do
        it "doesn't show the task" do
          claim = complete_provider_journey

          complete_practitioner_journey(
            claim: claim,
            one_login_first_name: "Robby",
            one_login_last_name: "Bobberson",
            one_login_date_of_birth: Date.new(1986, 1, 1),
            date_of_birth: Date.new(1986, 1, 1),
            payroll_gender: "Male"
          )

          sign_in_as_service_operator

          visit admin_claim_tasks_path(claim)

          expect(page).not_to have_content("Payroll gender")
        end
      end
    end
  end

  describe "matching_details" do
    context "when the practitioner has completed their half of the claim" do
      context "when the claim has matching details" do
        it "allows the admin to pass / fail the task" do
          claim = complete_provider_journey

          complete_practitioner_journey(
            claim: claim,
            one_login_first_name: "Robby",
            one_login_last_name: "Bobberson",
            one_login_date_of_birth: Date.new(1986, 1, 1),
            date_of_birth: Date.new(1986, 1, 1)
          )

          create(
            :claim,
            :submitted,
            :current_academic_year,
            email_address: claim.reload.email_address
          )

          sign_in_as_service_operator

          visit admin_claim_tasks_path(claim)

          expect(task_status("Matching details")).to eq("Incomplete")

          click_on "Review matching details from other claims"

          choose "Yes"

          click_on "Save and continue"

          visit admin_claim_tasks_path(claim)

          expect(task_status("Matching details")).to eq("Passed")
        end
      end

      context "when the claim doesn't have matching details" do
        it "doesn't show the task" do
          claim = complete_provider_journey

          complete_practitioner_journey(
            claim: claim,
            one_login_first_name: "Robby",
            one_login_last_name: "Bobberson",
            one_login_date_of_birth: Date.new(1986, 1, 1),
            date_of_birth: Date.new(1986, 1, 1)
          )

          sign_in_as_service_operator

          visit admin_claim_tasks_path(claim)

          expect(page).not_to have_content("Matching details")
        end
      end
    end
  end

  def complete_provider_journey
    create(:journey_configuration, :early_years_payment_provider_start)

    create(:journey_configuration, :early_years_payment_provider_authenticated)

    nursery = create(
      :eligible_ey_provider,
      primary_key_contact_email_address: "johndoe@example.com",
      secondary_contact_email_address: "janedoe@example.com"
    )

    visit landing_page_path(
      Journeys::EarlyYearsPayment::Provider::Start::ROUTING_NAME
    )

    click_link "Start now"

    fill_in "Email address", with: "johndoe@example.com"
    click_on "Submit"

    mail = ActionMailer::Base.deliveries.last
    magic_link = mail[:personalisation].unparsed_value[:magic_link]

    visit magic_link

    check(
      "I confirm that I’ve obtained consent from my employee and have " \
      "provided them with the relevant privacy notice."
    )
    click_button "Continue"

    choose nursery.nursery_name
    click_button "Continue"

    fill_in "claim-paye-reference-field", with: "123/123456SE90"
    click_button "Continue"

    fill_in "First name", with: "Bobby"
    fill_in "Last name", with: "Bobberson"
    click_button "Continue"

    date = Date.yesterday
    fill_in("Day", with: date.day)
    fill_in("Month", with: date.month)
    fill_in("Year", with: date.year)
    click_button "Continue"

    # /early-years-payment-provider/child-facing
    choose "Yes"
    click_button "Continue"

    # /early-years-payment-provider/returner
    choose "Yes"
    click_button "Continue"

    # /early-years-payment-provider/returner-worked-with-children
    choose "Yes"
    click_button "Continue"

    # /early-years-payment-provider/returner-contract-type
    choose "casual or temporary"
    click_button "Continue"

    # /early-years-payment-provider/employee-email
    fill_in(
      "claim-practitioner-email-address-field",
      with: "practitioner@example.com"
    )

    click_button "Continue"

    # /early-years-payment-provider/check-your-answers
    fill_in "claim-provider-contact-name-field", with: "John Doe"
    perform_enqueued_jobs { click_button "Accept and send" }

    Claim.last
  end

  def complete_practitioner_journey(
    claim:,
    date_of_birth:,
    one_login_first_name:,
    one_login_last_name:,
    one_login_date_of_birth:,
    payroll_gender: "Male"
  )
    stub_const(
      "OmniauthCallbacksController::ONE_LOGIN_TEST_USER",
      {
        first_name: one_login_first_name,
        last_name: one_login_last_name,
        date_of_birth: one_login_date_of_birth
      }
    )

    create(:journey_configuration, :early_years_payment_practitioner)

    visit "/early-years-payment-practitioner/find-reference?skip_landing_page=true&email=practitioner@example.com"

    fill_in "Enter your claim reference", with: claim.reference

    click_button "Submit"

    click_on "Continue"

    sign_in_with_one_login

    expect(page).to have_content("Personal details")
    fill_in "Day", with: date_of_birth.day
    fill_in "Month", with: date_of_birth.month
    fill_in "Year", with: date_of_birth.year
    fill_in "National Insurance number", with: "PX321499A"
    click_on "Continue"

    expect(page).to have_content("What is your address?")
    fill_in "House number or name", with: "57"
    fill_in "Building and street", with: "Walthamstow Drive"
    fill_in "Town or city", with: "Derby"
    fill_in "County", with: "City of Derby"
    fill_in "Postcode", with: "DE22 4BS"
    click_on "Continue"

    expect(page).to have_content("Your email address")
    fill_in "claim-email-address-field", with: "johndoe@example.com"
    click_on "Continue"

    expect(page).to have_content("Enter the 6-digit passcode")
    mail = ActionMailer::Base.deliveries.last
    otp_in_mail_sent = mail[:personalisation].unparsed_value[:one_time_password]
    fill_in "claim-one-time-password-field", with: otp_in_mail_sent
    click_on "Confirm"

    expect(page).to have_content("Would you like to provide your mobile number?")
    choose "No"
    click_on "Continue"

    fill_in "Name on your account", with: "#{claim.first_name} #{claim.surname}"
    fill_in "Sort code", with: "123456"
    fill_in "Account number", with: "87654321"
    click_on "Continue"

    expect(page).to have_text(I18n.t("forms.gender.questions.payroll_gender"))
    choose payroll_gender
    click_on "Continue"

    expect(page).to have_content("Check your answers before submitting this claim")

    perform_enqueued_jobs { click_on "Accept and send" }
  end

  def task_status(task_name)
    find("h2.app-task-list__section", text: task_name)
      .find(:xpath, 'following-sibling::ul//strong[contains(@class, "govuk-tag")]')
      .text
  end
end
