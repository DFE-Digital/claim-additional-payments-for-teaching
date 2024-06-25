module GetATeacherRelocationPayment
  module StepHelpers
    def when_i_start_the_form
      visit Journeys::GetATeacherRelocationPayment::SlugSequence.start_page_url

      click_link("Start")
    end

    def and_i_submit_the_application
      assert_on_check_your_answers_page!

      click_button("Confirm and send")
    end

    # FIXME RL make sure to remove this step it's just a temporary hack until
    # we've added the personal details pages. Really don't want to modify the db
    # in a feature spec!
    # Also we're only temporarily adding the teacher reference number, and
    # payroll gender to get the test to pass as we're not asking for it on the
    # IRP journey.
    def and_the_personal_details_section_has_been_temporarily_stubbed
      journey_session = Journeys::GetATeacherRelocationPayment::Session.last
      journey_session.answers.assign_attributes(
        attributes_for(
          :get_a_teacher_relocation_payment_answers,
          teacher_reference_number: "1234567"
        )
      )
      journey_session.save!
    end

    def and_i_complete_application_route_question_with(option:)
      choose(option)

      click_button("Continue")
    end

    def and_i_complete_the_state_funded_secondary_school_step_with(option:)
      assert_on_state_funded_secondary_school_page!

      choose(option)

      click_button("Continue")
    end

    def and_i_complete_the_contract_details_step_with(option:)
      assert_on_contract_details_page!

      choose(option)

      click_button("Continue")
    end

    def and_i_complete_the_contract_start_date_step_with(date:)
      assert_on_contract_start_date_page!

      fill_in("Day", with: date.day)
      fill_in("Month", with: date.month)
      fill_in("Year", with: date.year)

      click_button("Continue")
    end

    def and_i_complete_the_subject_step_with(option:)
      assert_on_subject_page!

      choose(option)

      click_button("Continue")
    end

    def and_i_complete_the_visa_screen_with(option:)
      assert_on_visa_page!

      select(option)

      click_button("Continue")
    end

    def and_i_complete_the_entry_date_page_with(date:)
      assert_on_entry_date_page!

      fill_in("Day", with: date.day)
      fill_in("Month", with: date.month)
      fill_in("Year", with: date.year)

      click_button("Continue")
    end

    def and_i_dont_change_my_answers
      click_button("Continue")
    end

    def and_i_complete_the_nationality_step_with(option:)
      assert_on_nationality_page!

      select(option)

      click_button("Continue")
    end

    def and_i_complete_the_passport_number_step_with(options:)
      assert_on_passport_number_page!

      fill_in(
        "Enter your passport number, as it appears on your passport",
        with: options
      )

      click_button("Continue")
    end

    def and_i_complete_the_personal_details_step
      assert_on_personal_details_page!

      fill_in("First name", with: "Walter")
      fill_in("Middle names", with: "Seymour")
      fill_in("Last name", with: "Skinner")
      fill_in("Day", with: "12")
      fill_in("Month", with: "7")
      fill_in("Year", with: "1945")
      fill_in("What is your National Insurance number", with: "QQ123456C")

      click_button("Continue")
    end

    def and_i_complete_the_postcode_step
      assert_on_postcode_page!

      allow_any_instance_of(OrdnanceSurvey::Client)
        .to receive_message_chain(:api, :search_places, :index)
        .and_return(
          [
            {
              address: "Flat 1, Millbrook Tower, Windermere Avenue, Southampton, SO16 9FX",
              address_line_1: "FLAT 1, MILLBROOK TOWER",
              address_line_2: "WINDERMERE AVENUE",
              address_line_3: "SOUTHAMPTON",
              postcode: "SO16 9FX"
            }
          ]
        )

      fill_in("Postcode", with: "SO16 9FX")

      click_on "Search"

      expect(page).to have_text("Select an address")
      choose "flat_1_millbrook_tower_windermere_avenue_southampton_so16_9fx"

      click_on "Continue"
    end

    def and_i_complete_the_manual_address_step
      assert_on_postcode_page!

      click_link("Enter your address manually")

      fill_in("House number or name", with: "Flat 1, Millbrook Tower")

      fill_in("Building and street", with: "Windermere Avenue")

      fill_in("Town or city", with: "Southampton")

      fill_in("Postcode", with: "SO16 9FX")

      click_button("Continue")
    end

    def and_i_complete_the_email_address_step
      assert_on_email_address_page!

      fill_in "Email address", with: "seymour.skinner@springfieldelementary.edu"

      click_on "Continue"

      fill_in "Enter the 6-digit passcode", with: get_otp_from_email

      click_on "Confirm"
    end

    def and_i_dont_provide_my_mobile_number
      assert_on_provider_mobile_number_page!

      choose "No"

      click_button("Continue")
    end

    def and_i_provide_my_mobile_number
      assert_on_provider_mobile_number_page!

      choose "Yes"

      click_button("Continue")

      otp_code = nil

      allow(NotifySmsMessage).to(
        receive(:new) { |args| otp_code = args.fetch(:personalisation).fetch(:otp) }
        .and_return(double(NotifySmsMessage, deliver!: true))
      )

      fill_in("Mobile number", with: "01234567890")

      click_button("Continue")

      fill_in("Enter the 6-digit passcode", with: otp_code)

      click_button "Confirm"
    end

    def and_i_provide_my_personal_bank_details
      assert_on_bank_or_building_society_page!

      choose "Personal bank account"

      click_button("Continue")

      assert_on_personal_bank_account_page!

      fill_in("Name on your account", with: "Walter Skinner")

      fill_in("Sort code", with: "123456")

      fill_in("Account number", with: "12345678")

      click_button("Continue")
    end

    def and_i_provide_my_building_society_details
      assert_on_bank_or_building_society_page!

      choose "Building society"

      click_button("Continue")

      assert_on_building_society_account_page!

      fill_in "Name on your account", with: "Walter Skinner"

      fill_in("Sort code", with: "123456")

      fill_in("Account number", with: "12345678")

      fill_in("Building society roll number", with: "12345678")

      click_button("Continue")
    end

    def and_i_complete_the_payroll_gender_step
      assert_on_payroll_gender_step!

      choose "Male"

      click_button("Continue")
    end

    def then_the_application_is_submitted_successfully
      assert_application_is_submitted!
    end

    def assert_on_state_funded_secondary_school_page!
      expect(page).to have_text(
        "Are you employed by an English state secondary school?"
      )
    end

    def assert_on_check_your_answers_part_one_page!
      expect(page).to have_text("Check your answers")
    end

    def assert_on_check_your_answers_page!
      expect(page).to have_text("Check your answers before sending your application")
    end

    def assert_on_contract_details_page!
      expect(page).to have_text("Are you employed on a contract lasting at least one year?")
    end

    def assert_on_contract_start_date_page!
      expect(page).to have_text("Enter the start date of your contract")
    end

    def assert_on_subject_page!
      expect(page).to have_text(
        "What subject are you employed to teach at your school?"
      )
    end

    def assert_on_visa_page!
      expect(page).to have_text("Select the visa you used to move to England")
    end

    def assert_on_entry_date_page!
      expect(page).to have_text(
        "Enter the date you moved to England to start your teaching job"
      )
    end

    def assert_on_nationality_page!
      expect(page).to have_text("Select your nationality")
    end

    def assert_on_passport_number_page!
      expect(page).to have_text(
        "Enter your passport number, as it appears on your passport"
      )
    end

    def assert_on_personal_details_page!
      expect(page).to have_text("What is your full name?")
    end

    def assert_on_postcode_page!
      expect(page).to have_text("What is your home address?")
    end

    def assert_on_email_address_page!
      expect(page).to have_text("Email address")
    end

    def assert_on_provider_mobile_number_page!
      expect(page).to have_text("Would you like to provide your mobile number?")
    end

    def assert_on_bank_or_building_society_page!
      expect(page).to have_text("What account do you want the money paid into?")
    end

    def assert_on_personal_bank_account_page!
      expect(page).to have_text("Enter your personal bank account details")
    end

    def assert_on_building_society_account_page!
      expect(page).to have_text("Enter your building society details")
    end

    def assert_on_payroll_gender_step!
      expect(page).to have_text(
        "How is your gender recorded on your school’s payroll system?"
      )
    end

    def assert_application_is_submitted!
      expect(page).to have_content("Claim submitted")
      expect(page).to have_content(
        "We have sent you a confirmation email to seymour.skinner@springfieldelementary.edu"
      )
    end
  end
end
