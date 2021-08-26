require "rails_helper"

RSpec.feature "Set Reminder when Eligible Later for an Early Career Payment" do
  [
    {subject: "chemistry", cohort: "2020 to 2021", academic_year: AcademicYear.new(2020), next_year: 2022, frozen_year: Date.new(2021, 9, 1)},
    {subject: "physics", cohort: "2020 to 2021", academic_year: AcademicYear.new(2020), next_year: 2022, frozen_year: Date.new(2021, 9, 1)},
    {subject: "mathematics", cohort: "2019 to 2020", academic_year: AcademicYear.new(2019), next_year: 2022, frozen_year: Date.new(2021, 9, 1)},
    {subject: "mathematics", cohort: "2020 to 2021", academic_year: AcademicYear.new(2020), next_year: 2022, frozen_year: Date.new(2021, 9, 1)}
  ].each do |args|
    scenario "Claimant enters peronal details and OTP for #{args[:subject]} for #{args[:cohort]}" do
      # set current date to academic year 2021 (or whatever is passed in from frozen_year)
      travel_to args[:frozen_year] do
        claim = start_early_career_payments_claim
        claim.eligibility.update!(
          attributes_for(
            :early_career_payments_eligibility,
            :eligible,
            eligible_itt_subject: args[:subject]
          )
        )

        expect(claim.policy).to eq EarlyCareerPayments
        expect(claim.eligibility.reload.eligible_itt_subject).to eq args[:subject]

        visit claim_path(EarlyCareerPayments.routing_name, "itt-year")

        choose args[:cohort]
        click_on "Continue"

        expect(claim.eligibility.reload.itt_academic_year).to eql args[:academic_year]

        # - Check your answers for eligibility
        expect(page).to have_text(I18n.t("early_career_payments.check_your_answers.part_one.primary_heading"))
        expect(page).to have_text(I18n.t("early_career_payments.check_your_answers.part_one.secondary_heading"))
        expect(page).to have_text(I18n.t("early_career_payments.check_your_answers.part_one.confirmation_notice"))

        expect(claim.eligibility.itt_academic_year).to eq args[:academic_year]
        expect(claim.errors.messages).to be_empty

        click_on "Continue"

        expect(page).to have_text("You will be eligible for an early-career payment in #{args[:next_year]}")

        expect(page).to have_content("Set up a reminder with us and we will email you when your application window opens.")

        click_on "Continue"

        expect(page).to have_text("Personal details")
        expect(page).to have_text("Tell us the email address you'd like us to send your reminder to. We recommend you use a personal email address.")

        fill_in "Full name", with: "David Tau"
        fill_in "Email address", with: "david.tau1988@hotmail.co.uk"
        click_on "Continue"
        fill_in "reminder_one_time_password", with: get_otp_from_email
        click_on "Confirm"
        reminder = Reminder.order(:created_at).last

        expect(reminder.full_name).to eq "David Tau"
        expect(reminder.email_address).to eq "david.tau1988@hotmail.co.uk"
        expect(reminder.itt_academic_year).to eq AcademicYear.new(args[:next_year])
        expect(reminder.itt_subject).to eq args[:subject]
        expect(page).to have_text("We have set your reminder")
        reminder_set_email = ActionMailer::Base.deliveries.last.body
        expect(reminder_set_email).to have_text("We will send you a reminder in September #{args[:next_year]}")
      end
    end
  end
end
