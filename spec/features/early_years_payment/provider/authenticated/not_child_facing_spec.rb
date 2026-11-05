require "rails_helper"

RSpec.feature "Early years payment provider child facing", :testing_persona do
  let(:email_address) { "johndoe@example.com" }
  let(:journey_session) { Journeys::EarlyYearsPayment::Provider::Authenticated::Session.last }
  let(:mail) { ActionMailer::Base.deliveries.last }
  let(:magic_link) { mail.personalisation[:magic_link] }
  let!(:nursery) { create(:eligible_ey_provider, primary_key_contact_email_address: email_address) }

  scenario "selecting No" do
    create(:journey_configuration, :early_years_payment_provider_authenticated)
    create(:journey_configuration, :early_years_payment_provider_start)

    visit landing_page_path(Journeys::EarlyYearsPayment::Provider::Start.routing_name)
    click_link "Start now"
    fill_in "Enter your email address", with: "johndoe@example.com"
    click_on "Submit"

    visit magic_link
    check "I confirm that I’ve obtained consent from my employee and have provided them with the relevant privacy notice."
    click_button "Continue"

    choose nursery.nursery_name
    click_button "Continue"

    fill_in "claim-paye-reference-field", with: "123/123456SE90"
    click_button "Continue"

    fill_in "First name", with: "Bobby"
    fill_in "Last name", with: "Bobberson"
    click_button "Continue"

    date = Date.yesterday
    fill_in("Day", with: date.day)
    fill_in("Month", with: date.month)
    fill_in("Year", with: date.year)
    click_button "Continue"

    choose "Permanent"
    click_button "Continue"

    expect(page.current_path).to eq "/early-years-payment-provider/child-facing"
    click_button "Continue"

    expect(page).to have_content "Select yes if Bobby Bobberson spends most of their time in their job working directly with children"
    choose "No"
    click_button "Continue"

    expect(page.current_path).to eq "/early-years-payment-provider/ineligible"
    expect(page).to have_content("Bobby is not eligible for this payment")
  end
end
