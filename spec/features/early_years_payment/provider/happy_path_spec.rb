require "rails_helper"

RSpec.feature "Early years payment provider" do
  let(:journey_session) { Journeys::EarlyYearsPayment::Provider::Session.last }
  let(:mail) { ActionMailer::Base.deliveries.last }
  let(:magic_link) { mail[:personalisation].unparsed_value[:magic_link] }

  scenario "magic link onwards" do
    when_early_years_payment_provider_journey_configuration_exists
    when_early_years_payment_start_journey_completed

    visit magic_link
    expect(journey_session.reload.answers.email_address).to eq "johndoe@example.com"
    expect(journey_session.reload.answers.email_verified).to be true
    expect(page).to have_content("Declaration of Employee Consent")
    check "I confirm that I have obtained consent from my employee and have provided them with the relevant privacy notice."
    click_button "Continue"
  end
end
