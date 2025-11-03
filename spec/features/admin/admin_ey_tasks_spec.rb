require "rails_helper"

RSpec.describe "Admin EY tasks" do
  around do |example|
    travel_to DateTime.new(2026, 2, 16, 9, 0, 0) do
      example.run
    end
  end

  describe "identity_confirmation" do
    context "when the practitioner has completed their half of the claim" do
      context "when OL IDV is a pass" do
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
          expect(task_status("One Login identity check")).to eq("Passed")
          click_on "Confirm the claimant made the claim"

          expect(page).to have_content(
            "This task was performed by GOV.UK One Login on " \
            "16 February 2026 9:00am"
          )
        end
      end

      context "when OL IDV is a fail" do
        it "marks task as No data" do
          claim = complete_provider_journey

          complete_practitioner_journey(
            claim: claim,
            one_login_first_name: "Bobby",
            one_login_last_name: "Bobberson",
            date_of_birth: Date.new(1986, 1, 11),
            one_login_date_of_birth: Date.new(1986, 1, 1),
            fail_idv: true
          )

          sign_in_as_service_operator

          visit admin_claim_tasks_path(claim)
          expect(task_status("One Login identity check")).to eq("No data")
          click_on "Confirm the claimant made the claim"

          expect(page).to have_text "This claimant was unable to verify their identity with GOV.UK One Login on"
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
          "This task will be available from 15 August 2026"
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
      Journeys::EarlyYearsPayment::Provider::Start.routing_name
    )

    click_link "Start now"

    fill_in "Enter your email address", with: "johndoe@example.com"
    click_on "Submit"

    mail = ActionMailer::Base.deliveries.last
    magic_link = mail.personalisation[:magic_link]

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

    # /early-years-payment-provider/contract-type
    choose "Permanent"
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
    choose "Casual or temporary"
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
    payroll_gender: "Male",
    fail_idv: false
  )
    allow(OmniauthCallbacksController::OneLoginTestUser).to(
      receive(:new).and_return(
        OpenStruct.new(
          first_name: one_login_first_name,
          surname: one_login_last_name,
          date_of_birth: one_login_date_of_birth
        )
      )
    )

    create(:journey_configuration, :early_years_payment_practitioner)

    visit "/early-years-payment-practitioner/find-reference?skip_landing_page=true&email=practitioner@example.com"
    fill_in "Enter your claim reference", with: claim.reference
    click_button "Submit"

    sign_in_with_one_login

    if fail_idv
      idv_with_one_login_with_return_codes
    else
      idv_with_one_login
    end

    if fail_idv
      expect(page).to have_content "We have not been able to confirm your identity via GOV.UK One Login"
    else
      expect(page).to have_content("You’ve successfully proved your identity with GOV.UK One Login")
    end
    click_on "Continue"

    expect(page).to have_content("How we will use your information")
    click_on "Continue"

    if fail_idv
      expect(page).to have_content("Personal details")
      expect(page).to have_content("Enter your full name")
      fill_in "First name(s)", with: one_login_first_name
      fill_in "Last name", with: one_login_last_name
      click_on "Continue"

      expect(page).to have_content("Personal details")
      expect(page).to have_content("Enter your date of birth")
      fill_in "Day", with: date_of_birth.day
      fill_in "Month", with: date_of_birth.month
      fill_in "Year", with: date_of_birth.year
      click_on "Continue"
    end

    expect(page).to have_content("Personal details")
    expect(page).to have_content("Enter your National Insurance number")
    fill_in "National Insurance number", with: "PX321499A"
    click_on "Continue"

    expect(page).to have_content("What is your home address?")
    click_on("Enter your address manually")

    expect(page).to have_content("What is your address?")
    fill_in "House number or name", with: "57"
    fill_in "Building and street", with: "Walthamstow Drive"
    fill_in "Town or city", with: "Derby"
    fill_in "County", with: "City of Derby"
    fill_in "Postcode", with: "DE22 4BS"
    click_on "Continue"

    expect(page).to have_content("What is your personal email address?")
    fill_in "claim-email-address-field", with: "johndoe@example.com"
    click_on "Continue"

    expect(page).to have_content("Enter the 6-digit passcode")
    mail = ActionMailer::Base.deliveries.last
    otp_in_mail_sent = mail.personalisation[:one_time_password]
    fill_in "claim-one-time-password-field", with: otp_in_mail_sent
    click_on "Confirm"

    expect(page).to have_content("Can we use your mobile number to contact you?")
    choose "No"
    click_on "Continue"

    fill_in "Name on the account", with: "#{claim.first_name} #{claim.surname}"
    fill_in "Sort code", with: "123456"
    fill_in "Account number", with: "87654321"
    click_on "Continue"

    expect(page).to have_text(
      "How is your gender recorded on your employer’s payroll system?"
    )
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
