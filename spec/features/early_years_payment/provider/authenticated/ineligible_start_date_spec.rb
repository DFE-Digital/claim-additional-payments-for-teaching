require "rails_helper"

RSpec.feature "Early years payment provider" do
  let(:email_address) { "johndoe@example.com" }
  let(:journey_session) { Journeys::EarlyYearsPayment::Provider::Authenticated::Session.last }
  let(:mail) { ActionMailer::Base.deliveries.last }
  let(:magic_link) { mail[:personalisation].unparsed_value[:magic_link] }
  let!(:nursery) { create(:eligible_ey_provider, primary_key_contact_email_address: email_address) }

  scenario "magic link onwards" do
    when_early_years_payment_provider_authenticated_journey_configuration_exists
    when_early_years_payment_provider_start_journey_completed

    visit magic_link
    expect(page).to have_content("Before you continue with your claim")
    expect(page.current_path).to eq "/early-years-payment-provider/consent"
    check "I confirm that I've obtained consent from my employee and have provided them with the relevant privacy notice."
    click_button "Continue"

    expect(journey_session.reload.answers.email_address).to be nil
    expect(journey_session.reload.answers.email_verified).to be nil
    expect(journey_session.reload.answers.provider_email_address).to eq email_address

    expect(page.current_path).to eq "/early-years-payment-provider/current-nursery"
    choose nursery.nursery_name
    click_button "Continue"

    expect(page.current_path).to eq "/early-years-payment-provider/paye-reference"
    expect(page).to have_content("What is #{nursery.nursery_name}’s employer PAYE reference?")
    fill_in "claim-paye-reference-field", with: "123/123456SE90"
    click_button "Continue"

    expect(page.current_path).to eq "/early-years-payment-provider/claimant-name"
    fill_in "First name", with: "Bobby"
    fill_in "Last name", with: "Bobberson"
    click_button "Continue"

    expect(page.current_path).to eq "/early-years-payment-provider/start-date"
    date = Policies::EarlyYearsPayments::POLICY_START_DATE - 10.days
    fill_in("Day", with: date.day)
    fill_in("Month", with: date.month)
    fill_in("Year", with: date.year)
    click_button "Continue"

    expect(page.current_path).to eq "/early-years-payment-provider/ineligible"
    expect(page).to have_content("This person may not be eligible")
  end
end
