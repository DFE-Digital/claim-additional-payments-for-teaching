require "rails_helper"

RSpec.feature "Early years payment provider" do
  let(:journey_session) { Journeys::EarlyYearsPayment::Provider::Authenticated::Session.last }
  let(:mail) { ActionMailer::Base.deliveries.last }
  let(:magic_link) { mail[:personalisation].unparsed_value[:magic_link] }

  scenario "magic link onwards" do
    when_early_years_payment_provider_authenticated_journey_configuration_exists
    when_early_years_payment_provider_start_journey_completed

    visit magic_link
    expect(journey_session.reload.answers.email_address).to eq "johndoe@example.com"
    expect(journey_session.reload.answers.email_verified).to be true
    expect(page).to have_content("Declaration of Employee Consent")
    check "I confirm that I have obtained consent from my employee and have provided them with the relevant privacy notice."
    click_button "Continue"
    expect(page.current_path).to eq "/early-years-payment-provider/current-nursery"
  end

  scenario "using magic link after having completed some of the journey" do
    when_early_years_payment_provider_authenticated_journey_configuration_exists
    when_early_years_payment_provider_start_journey_completed

    visit magic_link
    check "I confirm that I have obtained consent from my employee and have provided them with the relevant privacy notice."
    click_button "Continue"

    visit magic_link
    expect(page.current_path).to eq "/early-years-payment-provider/current-nursery"
  end
end
