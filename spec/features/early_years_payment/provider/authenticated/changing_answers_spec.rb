require "rails_helper"

RSpec.feature "Early years payment provider" do
  let(:email_address) { "johndoe@example.com" }
  let(:mail) { ActionMailer::Base.deliveries.last }
  let(:magic_link) { mail[:personalisation].unparsed_value[:magic_link] }
  let!(:nursery) { create(:eligible_ey_provider, primary_key_contact_email_address: email_address) }

  scenario "changing answers on the check-your-answers page" do
    when_early_years_payment_provider_authenticated_journey_configuration_exists
    when_early_years_payment_provider_start_journey_completed
    when_early_years_payment_provider_authenticated_journey_ready_to_submit

    find("a[href='#{claim_path(Journeys::EarlyYearsPayment::Provider::Authenticated::ROUTING_NAME, "paye-reference")}']").click
    expect(page).to have_content("What is #{nursery.nursery_name}’s employer PAYE reference?")
    fill_in "claim-paye-reference-field", with: "123/A"
    click_button "Continue"

    expect(page.current_path).to eq "/early-years-payment-provider/check-your-answers"
  end
end
