require "rails_helper"

RSpec.describe "Admin EY identity task" do
  around do |example|
    travel_to DateTime.new(2024, 10, 30, 9, 0, 0) do
      example.run
    end
  end

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
          "Claimant name from One login Bobby Bobberson"
        )

        expect(page).to have_content(
          "This task was performed by GOV.UK One Login on " \
          "30 October 2024 9:00am"
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

          expect(page).to have_content(
            "Provider entered claimant name Bobby Bobberson"
          )

          expect(page).to have_content(
            "Claimant name from One login Robby Bobberson"
          )

          expect(page).to have_content(
            "[GOV UK One Login Name] - Names partially match"
          )

          expect(page).to have_content('Provider: "Bobby Bobberson"')

          expect(page).to have_content('GOV.UK One Login: "Robby Bobberson"')
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

          expect(page).to have_content(
            "Provider entered claimant name Bobby Bobberson"
          )

          expect(page).to have_content(
            "Claimant name from One login Robby Robberson"
          )

          expect(page).to have_content(
            "[GOV UK One Login Name] - Names do not match"
          )

          expect(page).to have_content('Provider: "Bobby Bobberson"')

          expect(page).to have_content('GOV.UK One Login: "Robby Robberson"')
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

        expect(page).to have_content('GOV.UK One Login Name: "Bobby Bobberson"')

        expect(page).to have_content('GOV.UK One Login DOB: "1986-01-01"')

        expect(page).not_to have_button("Save and continue")
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
      "I confirm that I have obtained consent from my employee and have " \
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

    date = Policies::EarlyYearsPayments::POLICY_START_DATE + 1.day
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
    one_login_date_of_birth:
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

    visit "/early-years-payment-practitioner/find-reference?skip_landing_page=true"

    fill_in "Claim reference number", with: claim.reference

    click_button "Submit"

    sign_in_with_one_login

    click_on "Continue"

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
    choose "Male"
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
