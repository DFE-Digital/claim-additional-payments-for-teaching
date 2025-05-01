require "rails_helper"

RSpec.feature "Early years payment provider" do
  let(:email_address) { "johndoe@example.com" }
  let(:journey_session) { Journeys::EarlyYearsPayment::Provider::Authenticated::Session.last }
  let(:mail) { ActionMailer::Base.deliveries.last }
  let(:magic_link) { mail.personalisation[:magic_link] }
  let!(:nursery) { create(:eligible_ey_provider, primary_key_contact_email_address: email_address) }

  scenario "expired magic link" do
    travel(-20.minutes) do
      when_early_years_payment_provider_authenticated_journey_configuration_exists
      when_early_years_payment_provider_start_journey_completed
    end

    visit magic_link

    expect(journey_session.reload.answers.email_address).to eq nil
    expect(journey_session.reload.answers.email_verified).to be nil

    expect(page).to have_content("This link has expired")
    expect(page.current_path).to eq "/early-years-payment-provider/expired-link"
  end
end
