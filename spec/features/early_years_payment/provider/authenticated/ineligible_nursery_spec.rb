require "rails_helper"

RSpec.feature "Early years payment provider nurseries" do
  let(:email_address) { "johndoe@example.com" }
  let(:journey_session) { Journeys::EarlyYearsPayment::Provider::Authenticated::Session.last }
  let(:mail) { ActionMailer::Base.deliveries.last }
  let(:magic_link) { mail.personalisation[:magic_link] }
  let!(:nursery) { create(:eligible_ey_provider, primary_key_contact_email_address: email_address) }

  scenario "selecting none of the above" do
    when_early_years_payment_provider_authenticated_journey_configuration_exists
    when_early_years_payment_provider_start_journey_completed

    visit magic_link
    expect(journey_session.reload.answers.email_address).to be nil
    expect(journey_session.reload.answers.email_verified).to be nil
    expect(journey_session.reload.answers.provider_email_address).to eq email_address
    expect(page).to have_content("Before you continue with your claim")
    check "I confirm that I’ve obtained consent from my employee and have provided them with the relevant privacy notice."
    click_button "Continue"
    expect(page.current_path).to eq "/early-years-payment-provider/current-nursery"

    choose "None of the above"
    click_button "Continue"
    expect(page.current_path).to eq "/early-years-payment-provider/ineligible"
    expect(page).to have_content("This nursery is not eligible")
  end
end
