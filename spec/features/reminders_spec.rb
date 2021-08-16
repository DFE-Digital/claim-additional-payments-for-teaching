require "rails_helper"

RSpec.feature "Set Reminders when Eligible Later for an Early Career Payment" do
  scenario "Claimant enters peronal details and OTP" do
    claim = start_early_career_payments_claim
    claim.eligibility.update!(
      attributes_for(
        :early_career_payments_eligibility,
        :eligible,
        eligible_itt_subject: :chemistry
      )
    )

    expect(claim.policy).to eq EarlyCareerPayments
    expect(claim.eligibility.reload.eligible_itt_subject).to eq "chemistry"

    visit claim_path(EarlyCareerPayments.routing_name, "itt-year")

    choose "2020 to 2021"
    click_on "Continue"

    expect(claim.eligibility.reload.itt_academic_year).to eql AcademicYear.new(2020)

    # - Check your answers for eligibility
    expect(page).to have_text(I18n.t("early_career_payments.check_your_answers.part_one.primary_heading"))
    expect(page).to have_text(I18n.t("early_career_payments.check_your_answers.part_one.secondary_heading"))
    expect(page).to have_text(I18n.t("early_career_payments.check_your_answers.part_one.confirmation_notice"))

    expect(claim.eligibility.itt_academic_year).to eq AcademicYear.new(2020)
    expect(claim.errors.messages).to be_empty

    click_on "Continue"

    expect(page).to have_text("You will be eligible for an early-career payment in 2022")

    expect(page).to have_content("Set up a reminder with us and we will email you when your application window opens.")

    click_on "Continue"

    expect(page).to have_text("Personal details")
    expect(page).to have_text("Tell us the email address you'd like us to send your reminders to. We recommend you use a personal email address.")

    fill_in "Full name", with: "David Tau"
    fill_in "Email address", with: "david.tau1988@hotmail.co.uk"

    allow_any_instance_of(OneTimePassword::Validator).to receive(:valid?).and_return(true)
    click_on "Continue"
    fill_in "reminder_one_time_password", with: "123456"
    click_on "Confirm"
    reminder = Reminder.order(:created_at).last
    expect(reminder.full_name).to eq "David Tau"
    expect(reminder.email_address).to eq "david.tau1988@hotmail.co.uk"

    expect(page).to have_text("We have set your reminders")
    reminder_set_email = ActionMailer::Base.deliveries.last.body
    expect(reminder_set_email).to have_text("We will send you a reminder in September 2022")
  end
end
