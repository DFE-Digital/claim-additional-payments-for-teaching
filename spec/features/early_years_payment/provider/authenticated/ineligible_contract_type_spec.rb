require "rails_helper"

RSpec.feature "Early years payment provider", :testing_persona do
  let(:email_address) { "johndoe@example.com" }
  let(:journey_session) { Journeys::EarlyYearsPayment::Provider::Authenticated::Session.last }
  let(:mail) { ActionMailer::Base.deliveries.last }
  let(:magic_link) { mail.personalisation[:magic_link] }
  let!(:nursery) do
    create(
      :eligible_ey_provider,
      primary_key_contact_email_address: email_address,
      nursery_name: "Springfield Daycare"
    )
  end

  scenario "ineligible contract type" do
    create(:journey_configuration, :early_years_payment_provider_authenticated)
    create(:journey_configuration, :early_years_payment_provider_start)

    visit landing_page_path(Journeys::EarlyYearsPayment::Provider::Start.routing_name)
    click_link "Start now"
    fill_in "Enter your email address", with: "johndoe@example.com"
    click_on "Submit"

    visit magic_link
    expect(page).to have_content("Before you continue with your claim")
    expect(page.current_path).to eq "/early-years-payment-provider/consent"
    check "I confirm that I’ve obtained consent from my employee and have provided them with the relevant privacy notice."
    click_button "Continue"

    expect(page.current_path).to eq "/early-years-payment-provider/current-nursery"
    choose nursery.nursery_name
    click_button "Continue"

    expect(page.current_path).to eq "/early-years-payment-provider/paye-reference"
    expect(page).to(
      have_content("What is Springfield Daycare’s employer PAYE reference?")
    )
    fill_in "claim-paye-reference-field", with: "123/123456SE90"
    click_button "Continue"

    expect(page.current_path).to eq "/early-years-payment-provider/claimant-name"
    fill_in "First name", with: "Edna"
    fill_in "Last name", with: "Krabappel"
    click_button "Continue"

    expect(page.current_path).to eq "/early-years-payment-provider/start-date"
    date = Date.yesterday
    fill_in("Day", with: date.day)
    fill_in("Month", with: date.month)
    fill_in("Year", with: date.year)
    click_button "Continue"

    expect(page.current_path).to eq "/early-years-payment-provider/contract-type"
    choose "Casual or temporary"
    click_button "Continue"

    expect(page).to have_content("Edna is not eligible for this payment")
  end
end
