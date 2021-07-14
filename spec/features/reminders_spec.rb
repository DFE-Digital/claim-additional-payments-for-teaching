require "rails_helper"

RSpec.describe "Set Reminders when Eligible Later for an Early Career Payment" do
  it "Claimant can enter personal details" do
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

    choose "2020 - 2021"
    click_on "Continue"

    expect(claim.eligibility.reload.itt_academic_year).to eql "2020_2021"

    # - Check your answers for eligibility
    expect(page).to have_text(I18n.t("early_career_payments.check_your_answers.part_one.primary_heading"))
    expect(page).to have_text(I18n.t("early_career_payments.check_your_answers.part_one.secondary_heading"))
    expect(page).to have_text(I18n.t("early_career_payments.check_your_answers.part_one.confirmation_notice"))

    expect(claim.eligibility.itt_academic_year).to eq "2020_2021"
    expect(claim.errors.messages).to be_empty

    click_on "Continue"

    expect(page).to have_text("You will be eligible for an early-career payment in 2022")

    expect(page).to have_content("Set up a reminder with us and we will email you when your application window opens.")

    click_on "Continue"

    expect(page).to have_text("Personal details")
    expect(page).to have_text("Tell us the email address you'd like us to send your reminders to. We recommend you use a personal email address.")

    fill_in "Full name", with: "Miss Sandia Patel"
    fill_in "Email address", with: "s.patel2000gb@gmail.com"

    click_on "Continue"

    reminder = Reminder.order(:created_at).last
    expect(reminder.full_name).to eq "Miss Sandia Patel"
    expect(reminder.email_address).to eq "s.patel2000gb@gmail.com"

    expect(page).to have_text("We have set your reminders")
  end
end
