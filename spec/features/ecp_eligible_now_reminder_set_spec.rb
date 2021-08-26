require "rails_helper"

RSpec.feature "Elible now can set a reminder for next year." do
  it "auto-sets a reminders email and name from claim params and displays the correct year" do
    Timecop.freeze(Date.new(2021, 9, 1)) do
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
      fill_in "reminder_one_time_password", with: get_otp_from_email
      click_on "Confirm"
      expect(page).to have_text("We will send you a reminder in September 2023")
    end
  end
end
