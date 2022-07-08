require "rails_helper"

# TODO - LUPP claims change behaviour. These scenarios to be fixed when reminder service stories are progressed
RSpec.feature "Set Reminder when Eligible Later for an Early Career Payment", pending: "Reminder service" do
  [
    {subject: "chemistry", cohort: "2020 to 2021", academic_year: AcademicYear.new(2020), next_year: 2022, frozen_year: Date.new(2021, 9, 1)},
    {subject: "physics", cohort: "2020 to 2021", academic_year: AcademicYear.new(2020), next_year: 2022, frozen_year: Date.new(2021, 9, 1)},
    {subject: "mathematics", cohort: "2019 to 2020", academic_year: AcademicYear.new(2019), next_year: 2022, frozen_year: Date.new(2021, 9, 1)},
    {subject: "mathematics", cohort: "2020 to 2021", academic_year: AcademicYear.new(2020), next_year: 2022, frozen_year: Date.new(2021, 9, 1)}
  ].each do |args|
    let(:mail) { ReminderMailer.reminder_set(Reminder.order(:created_at).last) }

    scenario "Claimant enters personal details and OTP for #{args[:subject]} for #{args[:cohort]}" do
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

        # - Which subject did you do your postgraduate initial teacher training (ITT) in?
        choose I18n.t("early_career_payments.answers.eligible_itt_subject.#{args[:subject]}")
        click_on "Continue"

        # - Do you teach subject now?
        choose "Yes"
        click_on "Continue"

        expect(claim.eligibility.reload.itt_academic_year).to eql args[:academic_year]

        # - Check your answers for eligibility
        expect(page).to have_text(I18n.t("early_career_payments.check_your_answers.part_one.primary_heading"))
        expect(page).to have_text(I18n.t("early_career_payments.check_your_answers.part_one.secondary_heading"))
        expect(page).to have_text(I18n.t("early_career_payments.check_your_answers.part_one.confirmation_notice"))

        expect(claim.eligibility.itt_academic_year).to eq args[:academic_year]
        expect(claim.errors.messages).to be_empty

        click_on "Continue"

        expect(page).to have_text("You will be eligible")
        expect(page).to have_text("early-career payment in #{args[:next_year]}")

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
        expect(mail[:template_id].decoded).to eq "0dc80ba9-adae-43cd-98bf-58882ee401c3"
      end
    end
  end

  context "Claimant re-requests the OTP 6-digit password after entering their Personal Details" do
    before do
      @ecp_policy_date = PolicyConfiguration.for(EarlyCareerPayments).current_academic_year
      PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: AcademicYear.new(2022))
    end

    after do
      PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: @ecp_policy_date)
    end

    [
      {subject: "mathematics", cohort: "2018 to 2019", academic_year: AcademicYear.new(2018), next_year: 2023, frozen_year: Date.new(2022, 10, 5)}
    ].each do |args|
      scenario "to request a reminder for #{args[:subject]} for #{args[:cohort]}" do
        skip "this flips between passing and failing but won't address now"
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

          choose I18n.t("early_career_payments.answers.eligible_itt_subject.#{args[:subject]}")
          click_on "Continue"

          # - Do you teach subject now?
          choose "Yes"
          click_on "Continue"

          # - Check your answers for eligibility
          expect(page).to have_text(I18n.t("early_career_payments.check_your_answers.part_one.primary_heading"))
          expect(page).to have_text(I18n.t("early_career_payments.check_your_answers.part_one.secondary_heading"))
          expect(page).to have_text(I18n.t("early_career_payments.check_your_answers.part_one.confirmation_notice"))

          expect(claim.eligibility.itt_academic_year).to eq args[:academic_year]
          expect(claim.errors.messages).to be_empty

          click_on "Continue"

          expect(page).to have_text("You will be eligible")
          expect(page).to have_text("early-career payment in #{args[:next_year]}")

          expect(page).to have_content("Set up a reminder with us and we will email you when your application window opens.")

          click_on "Continue"

          expect(page).to have_text("Personal details")
          expect(page).to have_text("Tell us the email address you'd like us to send your reminder to. We recommend you use a personal email address.")

          fill_in "Full name", with: "David Tau"
          fill_in "Email address", with: "david.tau1988@hotmail.co.uk"
          click_on "Continue"

          expect(page).to have_link("Resend password (goes back to the personal details page)", href: new_reminder_path(policy: claim.policy.routing_name))

          click_link "Resend password"
          expect(page).to have_text("Personal details")
          click_on "Continue"

          fill_in "reminder_one_time_password", with: get_otp_from_email
          click_on "Confirm"
          reminder = Reminder.order(:created_at).last

          expect(reminder.full_name).to eq "David Tau"
          expect(reminder.email_address).to eq "david.tau1988@hotmail.co.uk"
          expect(reminder.itt_academic_year).to eq AcademicYear.new(args[:next_year])
          expect(reminder.itt_subject).to eq args[:subject]
          expect(page).to have_text("We have set your reminder")
          expect(mail[:template_id].decoded).to eq "0dc80ba9-adae-43cd-98bf-58882ee401c3"
        end
      end
    end
  end
end
