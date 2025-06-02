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

    def and_i_complete_changed_workplace_or_new_contract_with(option:)
      assert_on_changed_workplace_or_new_contract_page!

      choose(option)

      click_button("Continue")
    end

    def and_i_complete_breaks_in_employment_with(option:)
      assert_on_breaks_in_employment_page!

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

    def and_i_complete_the_current_school_step(school)
      assert_on_current_school_page!

      fill_in(
        "Which school are you currently employed to teach at?",
        with: school.name
      )

      click_button "Continue"

      unless page.has_text?("Select your school from the search results")
        # We've got stuck on the school search page, try again
        click_button "Continue"
      end

      choose school.name

      click_button "Continue"
    end

    def and_i_complete_the_headteacher_step
      assert_on_headteacher_page!

      fill_in(
        "Enter the name of the headteacher of the school where you are employed as a teacher",
        with: "Seymour Skinner"
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
      choose "Flat 1, Millbrook Tower, Windermere Avenue, Southampton, SO16 9FX"
      click_on "Continue"
    end

    def and_i_complete_the_manual_address_step
      assert_on_postcode_page!

      click_button("Enter your address manually")

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
      assert_on_personal_bank_account_page!

      fill_in("Name on your account", with: "Walter Skinner")
      fill_in("Sort code", with: "123456")
      fill_in("Account number", with: "12345678")

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

    def assert_on_changed_workplace_or_new_contract_page!
      expect(page).to have_text("Have you changed your workplace or started a new contract in the past year?")
    end

    def assert_on_breaks_in_employment_page!
      expect(page).to have_text("Have you had any breaks in employment during the last 3 academic terms?")
    end

    def assert_on_visa_page!
      expect(page).to have_text("Select the visa you currently have to live in England")
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

    def assert_on_current_school_page!
      expect(page).to have_text(
        "Which school are you currently employed to teach at?"
      )
    end

    def assert_on_headteacher_page!
      expect(page).to have_text(
        "Enter the name of the headteacher of the school where you are employed as a teacher"
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

    def assert_on_personal_bank_account_page!
      expect(page).to have_text("Enter your personal bank account details")
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

    def then_i_change_answer(question)
      click_link question
    end

    def when_i_click_back_link
      click_link "Back"
    end
  end
end
