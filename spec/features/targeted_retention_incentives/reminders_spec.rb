require "rails_helper"

RSpec.describe "Targeted retention incentives reminders" do
  before { FeatureFlag.enable!(:tri_only_journey) }

  context "when a trainee teacher" do
    it "allows the user to set a reminder" do
      policy_end_year = Policies::TargetedRetentionIncentivePayments::POLICY_END_YEAR

      current_academic_year = policy_end_year - 1

      create(
        :journey_configuration,
        :targeted_retention_incentive_payments_only,
        teacher_id_enabled: true,
        current_academic_year: current_academic_year
      )

      school = create(
        :school,
        :targeted_retention_incentive_payments_eligible
      )

      visit Journeys::TargetedRetentionIncentivePayments.start_page_url

      click_on "Start now"

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

      travel_to(next_academic_year.start_of_autumn_term) do
        perform_enqueued_jobs do
          # This is triggered when the journey is reopened
          SendReminderEmailsJob.perform_now(
            Journeys::TargetedRetentionIncentivePayments
          )
        end
      end

      expect("bergstrom@springfield-elementary.edu").to have_received_email(
        ApplicationMailer::REMINDER_APPLICATION_WINDOW_OPEN_NOTIFY_TEMPLATE_ID
      )
    end
  end
end
