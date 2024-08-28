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
    expect(journey_session.reload.answers.email_address).to eq email_address
    expect(journey_session.reload.answers.email_verified).to be true
    expect(page).to have_content("Declaration of Employee Consent")
    expect(page.current_path).to eq "/early-years-payment-provider/consent"
    check "I confirm that I have obtained consent from my employee and have provided them with the relevant privacy notice."
    click_button "Continue"

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
    date = Date.yesterday
    fill_in("Day", with: date.day)
    fill_in("Month", with: date.month)
    fill_in("Year", with: date.year)
    click_button "Continue"

    expect(page.current_path).to eq "/early-years-payment-provider/child-facing"
    check "I confirm that at least 70% of Bobby’s time in their job is spent working directly with children."
    click_button "Continue"

    expect(page.current_path).to eq "/early-years-payment-provider/returner"
    choose "No"
    click_button "Continue"

    expect(page.current_path).to eq "/early-years-payment-provider/employee-email"
    fill_in "claim-practitioner-email-address-field", with: "practitioner@example.com"
    click_button "Continue"

    expect(page.current_path).to eq "/early-years-payment-provider/check-your-answers"
    expect(page).to have_content("Check your answers before submitting this claim")
    fill_in "claim-provider-contact-name-field", with: "John Doe"
    click_button "Accept and send"

    expect(page.current_path).to eq claim_confirmation_path(Journeys::EarlyYearsPayment::Provider::Authenticated::ROUTING_NAME)
    expect(Claim.last.provider_contact_name).to eq "John Doe"
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
