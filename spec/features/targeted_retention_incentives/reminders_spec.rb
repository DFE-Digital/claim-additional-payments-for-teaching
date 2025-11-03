require "rails_helper"

RSpec.describe "Targeted retention incentives reminders" do
  context "when a trainee teacher" do
    it "allows the user to set a reminder" do
      policy_end_year = Policies::TargetedRetentionIncentivePayments::POLICY_END_YEAR

      current_academic_year = policy_end_year - 1

      create(
        :journey_configuration,
        :targeted_retention_incentive_payments,
        teacher_id_enabled: true,
        current_academic_year: current_academic_year
      )

      school = create(
        :school,
        :targeted_retention_incentive_payments_eligible
      )

      visit Journeys::TargetedRetentionIncentivePayments.start_page_url

      click_on "Start now"

      # check-eligibility-intro
      click_through_check_eligibility_intro

      # sign-in-or-continue
      click_on "Continue without signing in"

      # current-school
      fill_in "Which school do you teach at?", with: school.name
      click_on "Continue"

      # current-school part 2
      choose school.name
      click_on "Continue"

      # nqt-in-academic-year-after-itt - select No (trainee teacher)
      choose "No, I’m a trainee teacher"
      click_on "Continue"

      # eligible-itt-subject
      choose "Physics"
      click_on "Continue"

      # future-eligibility
      expect(page).to have_content("You are not eligible this year")

      click_on "Set reminder"

      fill_in "Full name", with: "Mr. Bergstrom"

      fill_in "Email address", with: "bergstrom@springfield-elementary.edu"

      perform_enqueued_jobs do
        click_on "Continue"
      end

      mail = ActionMailer::Base.deliveries.last
      otp_in_mail_sent = mail.personalisation[:one_time_password]

      fill_in "Enter the 6-digit passcode", with: otp_in_mail_sent
      click_on "Confirm"

      expect(page).to have_content("We have set your reminder")

      next_academic_year = current_academic_year + 1

      # We stub the academic year rather than use `travel_to` as on CI
      # `travel_to` doesn't change the academic year
      allow(AcademicYear).to receive(:current).and_return(next_academic_year)

      perform_enqueued_jobs do
        # This is triggered when the journey is reopened
        SendReminderEmailsJob.perform_now(
          Journeys::TargetedRetentionIncentivePayments
        )
      end

      expect("bergstrom@springfield-elementary.edu").to have_received_email(
        ApplicationMailer::REMINDER_APPLICATION_WINDOW_OPEN_NOTIFY_TEMPLATE_ID
      )
    end
  end

  context "when a teacher" do
    let(:current_academic_year) { AcademicYear.new(2024) }

    before do
      create(
        :journey_configuration,
        :targeted_retention_incentive_payments,
        current_academic_year: current_academic_year
      )

      school = create(
        :school,
        :targeted_retention_incentive_payments_eligible
      )

      visit Journeys::TargetedRetentionIncentivePayments.start_page_url

      click_on "Start now"

      # check-eligibility-intro
      click_through_check_eligibility_intro

      # sign-in-or-continue
      click_on "Continue without signing in"

      # current-school
      fill_in "Which school do you teach at?", with: school.name
      click_on "Continue"

      # current-school part 2
      choose school.name
      click_on "Continue"

      # nqt-in-academic-year-after-itt
      choose "Yes"
      click_on "Continue"

      # supply-teacher
      choose "No"
      click_on "Continue"

      # poor-performance
      all(".govuk-radios__label").select { it.text == "No" }.each(&:click)
      click_on "Continue"

      # qualification
      choose "Postgraduate initial teacher training (ITT)"
      click_on "Continue"

      # itt-year
      choose itt_year.to_s(:long)
      click_on "Continue"

      # eligible-itt-subject
      choose "Physics"
      click_on "Continue"

      # teaching-subject-now
      choose "Yes"
      click_on "Continue"

      # Check you answers part one
      click_on "Continue"

      click_on "Apply now"

      # information-provided
      expect(page).to have_text(
        "How we will use the information you provide"
      )
      click_on "Continue"

      # Personal details
      fill_in "First name", with: "Seymour"
      fill_in "Last name", with: "Skinner"

      fill_in "Day", with: "23"
      fill_in "Month", with: "10"
      fill_in "Year", with: "1953"

      fill_in "National Insurance number", with: "AB123456C"
      click_on "Continue"

      click_on "Enter your address manually"

      fill_in "House number or name", with: "Test house"
      fill_in "Building and street", with: "Test street"
      fill_in "Town or city", with: "Test town"
      fill_in "County", with: "Testshire"
      fill_in "Postcode", with: "TE57 1NG"
      click_on "Continue"

      fill_in "Email address", with: "seymour.skinner@springfield-elementary.edu"
      click_on "Continue"

      mail = ActionMailer::Base.deliveries.last
      otp_in_mail_sent = mail.personalisation[:one_time_password]

      fill_in "Enter the 6-digit passcode", with: otp_in_mail_sent
      click_on "Confirm"

      # provide-mobile-number
      choose "No"
      click_on "Continue"

      fill_in "Name on your account", with: "Seymour Skinner"
      fill_in "Sort code", with: "000000"
      fill_in "Account number", with: "00000000"
      click_on "Continue"

      # gender
      choose "Male"
      click_on "Continue"

      # trn
      fill_in "What is your teacher reference number (TRN)?", with: "1234567"
      click_on "Continue"

      click_on "Accept and send"
    end

    context "when itt year is not eligible next year" do
      # itt year will be outside the range of eligible itt years next year
      let(:itt_year) { (current_academic_year - 5) }

      it "doesn't allow setting a reminder" do
        expect(page).to have_content(
          "You applied for a targeted retention incentive payment"
        )

        expect(page).not_to have_content("Set reminder")
      end
    end

    context "when itt year is still eligible next year" do
      let(:itt_year) { (current_academic_year - 1) }

      it "allows setting a reminder" do
        expect(page).to have_content(
          "You applied for a targeted retention incentive payment"
        )

        click_on "Set reminder"

        expect(page).to have_content("We have set your reminder")

        next_academic_year = current_academic_year + 1

        # We stub the academic year rather than use `travel_to` as on CI
        # `travel_to` doesn't change the academic year
        allow(AcademicYear).to receive(:current).and_return(next_academic_year)

        perform_enqueued_jobs do
          # This is triggered when the journey is reopened
          SendReminderEmailsJob.perform_now(
            Journeys::TargetedRetentionIncentivePayments
          )
        end

        expect("seymour.skinner@springfield-elementary.edu").to(
          have_received_email(
            ApplicationMailer::REMINDER_APPLICATION_WINDOW_OPEN_NOTIFY_TEMPLATE_ID
          )
        )
      end
    end
  end
end
