require "rails_helper"

RSpec.feature "Early years payment provider" do
  let(:email_address) { "johndoe@example.com" }
  let(:mail) { ActionMailer::Base.deliveries.last }
  let(:magic_link) { mail.personalisation[:magic_link] }
  let!(:nursery) { create(:eligible_ey_provider, primary_key_contact_email_address: email_address) }

  scenario "when the submitter name is omitted on the check-your-answers page" do
    when_early_years_payment_provider_authenticated_journey_configuration_exists
    when_early_years_payment_provider_start_journey_completed
    when_early_years_payment_provider_authenticated_journey_ready_to_submit
    click_button "Accept and send"

    expect(page.current_path).to eq "/early-years-payment-provider/check-your-answers"
    expect(page).to have_content "You cannot submit this claim without providing your full name"

    fill_in "claim-provider-contact-name-field-error", with: "John Doe"
    click_button "Accept and send"

    expect(page.current_path).to eq claim_path(Journeys::EarlyYearsPayment::Provider::Authenticated.routing_name, slug: "confirmation")
  end
end
