require "rails_helper"

RSpec.feature "Elible now can set a reminder for next year." do
  it "auto-sets a reminders email and name from claim params and displays the correct year" do
    claim = start_early_career_payments_claim
    claim.update!(attributes_for(:claim, :submittable))
    claim.eligibility.update!(attributes_for(:early_career_payments_eligibility, :eligible))
    visit claim_path(claim.policy.routing_name, "check-your-answers")
    expect(page).to have_text(claim.first_name)
    click_on "Accept and send"
    expect(page).to have_text("Set a reminder for when your application window opens")
    click_on "Continue"
    expect(page).to have_field("reminder_email_address", with: claim.email_address)
    expect(page).to have_field("reminder_full_name", with: claim.full_name)
    click_on "Continue"
    allow_any_instance_of(OneTimePassword::Validator).to receive(:valid?).and_return(true)
    fill_in "reminder_one_time_password", with: "123456"
    click_on "Confirm"
    expect(page).to have_text("We will send you a reminder in 2023")
  end
end
