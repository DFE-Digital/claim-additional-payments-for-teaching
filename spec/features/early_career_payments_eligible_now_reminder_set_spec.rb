require "rails_helper"

RSpec.feature "Elible now can set a reminder for next year." do
  it "auto-sets a reminders email and name from claim params and displays the correct year" do
    travel_to Date.new(2021, 9, 1) do
      claim = start_early_career_payments_claim
      claim.update!(attributes_for(:claim, :submittable))
      claim.eligibility.update!(attributes_for(:early_career_payments_eligibility, :eligible))
      visit claim_path(claim.policy.routing_name, "check-your-answers")
      expect(page).to have_text(claim.first_name)
      click_on "Accept and send"
      expect(page).to have_text("Set a reminder for when your next application window opens")
      click_on "Set reminder"
      expect(page).to have_field("reminder_email_address", with: claim.email_address)
      expect(page).to have_field("reminder_full_name", with: claim.full_name)
      click_on "Continue"
      fill_in "reminder_one_time_password", with: get_otp_from_email
      click_on "Confirm"
      expect(page).to have_text("We will send you a reminder in September 2023")
    end
  end
end

RSpec.feature "Completed Applications - Reminders" do
  [
    {
      policy_year: AcademicYear.new(2021),
      eligible_now: [
        {itt_subject: "mathematics", itt_academic_year: AcademicYear.new(2018), invited_to_set_reminder: true}
      ]
    },
    {
      policy_year: AcademicYear.new(2022),
      eligible_now: [
        {itt_subject: "mathematics", itt_academic_year: AcademicYear.new(2019), invited_to_set_reminder: true},
        {itt_subject: "mathematics", itt_academic_year: AcademicYear.new(2020), invited_to_set_reminder: true},
        {itt_subject: "chemistry", itt_academic_year: AcademicYear.new(2020), invited_to_set_reminder: true},
        {itt_subject: "foreign_languages", itt_academic_year: AcademicYear.new(2020), invited_to_set_reminder: true},
        {itt_subject: "physics", itt_academic_year: AcademicYear.new(2020), invited_to_set_reminder: true}
      ]
    },
    {
      policy_year: AcademicYear.new(2023),
      eligible_now: [
        {itt_subject: "mathematics", itt_academic_year: AcademicYear.new(2018), invited_to_set_reminder: false},
        {itt_subject: "mathematics", itt_academic_year: AcademicYear.new(2020), invited_to_set_reminder: true},
        {itt_subject: "chemistry", itt_academic_year: AcademicYear.new(2020), invited_to_set_reminder: true},
        {itt_subject: "foreign_languages", itt_academic_year: AcademicYear.new(2020), invited_to_set_reminder: true},
        {itt_subject: "physics", itt_academic_year: AcademicYear.new(2020), invited_to_set_reminder: true}
      ]
    },
    {
      policy_year: AcademicYear.new(2024),
      eligible_now: [
        {itt_subject: "mathematics", itt_academic_year: AcademicYear.new(2020), invited_to_set_reminder: false},
        {itt_subject: "mathematics", itt_academic_year: AcademicYear.new(2020), invited_to_set_reminder: false},
        {itt_subject: "chemistry", itt_academic_year: AcademicYear.new(2020), invited_to_set_reminder: false},
        {itt_subject: "foreign_languages", itt_academic_year: AcademicYear.new(2020), invited_to_set_reminder: false},
        {itt_subject: "physics", itt_academic_year: AcademicYear.new(2020), invited_to_set_reminder: false}
      ]
    }
  ].each do |policy|
    context "when accepting claims for AcademicYear #{policy[:policy_year]}" do
      before do
        @ecp_policy_date = PolicyConfiguration.for(EarlyCareerPayments).current_academic_year
        PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: policy[:policy_year])
      end

      after do
        PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: @ecp_policy_date)
      end

      let(:claim) do
        claim = start_early_career_payments_claim
        claim.update!(attributes_for(:claim, :submittable))
        claim.eligibility.update!(attributes_for(:early_career_payments_eligibility, :eligible))
        claim
      end

      policy[:eligible_now].each do |scenario|
        reminder_status = scenario[:invited_to_set_reminder] == true ? "CAN" : "CANNOT"
        scenario "with cohort ITT subject #{scenario[:itt_subject]} in ITT academic year #{scenario[:itt_academic_year]} - a reminder #{reminder_status} be set" do
          claim.eligibility.update(
            eligible_itt_subject: scenario[:itt_subject],
            itt_academic_year: scenario[:itt_academic_year]
          )

          visit claim_path(claim.policy.routing_name, "check-your-answers")
          expect(page).to have_text(claim.first_name)

          click_on "Accept and send"

          expect(page).to have_text("Application complete")
          expect(page).to have_text("Your reference number")
          expect(page).to have_text(claim.reload.reference.to_s)

          if scenario[:invited_to_set_reminder] == true
            expect(page).to have_text("Set a reminder for when your next application window opens")
            click_on "Set reminder"
            expect(page).to have_field("reminder_email_address", with: claim.email_address)
            expect(page).to have_field("reminder_full_name", with: claim.full_name)
            click_on "Continue"
            fill_in "reminder_one_time_password", with: get_otp_from_email
            click_on "Confirm"
            expect(page).to have_text("We will send you a reminder in September #{claim.eligibility.eligible_later_year.start_year}")
          elsif scenario[:invited_to_set_reminder] == false
            expect(page).not_to have_text("Set a reminder for when your next application window opens")
            expect(page).not_to have_link("Set reminder")
          end
          expect(page).to have_text("What did you think of this service?")
        end
      end
    end
  end
end
