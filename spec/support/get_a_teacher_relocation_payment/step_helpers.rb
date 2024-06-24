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
          :with_personal_details,
          :with_email_details,
          :with_mobile_details,
          :with_bank_details,
          email_address: "test-irp-claim@example.com",
          teacher_reference_number: "1234567",
          payroll_gender: "male"
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

    def and_i_complete_the_trainee_details_step_with(option:)
      assert_on_trainee_details_page!

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

    def and_i_dont_change_my_answers
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

    def assert_on_trainee_details_page!
      expect(page).to have_text(
        "Are you on a teacher training course in England which meets the following conditions?"
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

    def assert_application_is_submitted!
      expect(page).to have_content("Claim submitted")
      expect(page).to have_content(
        "We have sent you a confirmation email to test-irp-claim@example.com"
      )
    end
  end
end