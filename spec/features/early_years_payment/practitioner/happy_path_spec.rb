require "rails_helper"

RSpec.feature "Early years payment practitioner" do
  scenario "Happy path" do
    when_early_years_payment_practitioner_journey_configuration_exists

    visit landing_page_path(Journeys::EarlyYearsPayment::Practitioner::ROUTING_NAME)

    # find-reference page stuff
    visit claim_path(Journeys::EarlyYearsPayment::Practitioner::ROUTING_NAME, :claim) # temporary step until landing page implemented
    click_on "Continue"

    # one login stuff
    click_on "Continue"

    expect(page.title).to have_text("How we’ll use the information you provide")
    expect(page).to have_content("How we’ll use the information you provide")
    click_on "Continue"

    expect(page).to have_content("Personal details")
    fill_in "First name", with: "John"
    fill_in "Last name", with: "Doe"
    fill_in "Day", with: "28"
    fill_in "Month", with: "2"
    fill_in "Year", with: "1988"
    fill_in "National Insurance number", with: "PX321499A"
    click_on "Continue"

    expect(page.title).to have_text("What is your address?")
    expect(page).to have_content("What is your address?")
    fill_in "House number or name", with: "57"
    fill_in "Building and street", with: "Walthamstow Drive"
    fill_in "Town or city", with: "Derby"
    fill_in "County", with: "City of Derby"
    fill_in "Postcode", with: "DE22 4BS"
    click_on "Continue"

    expect(page.title).to have_text("Your email address")
    expect(page).to have_content("Your email address")
    fill_in "claim-email-address-field", with: "johndoe@example.com"
    click_on "Continue"

    expect(page).to have_content("Enter the 6-digit passcode")
    mail = ActionMailer::Base.deliveries.last
    otp_in_mail_sent = mail[:personalisation].unparsed_value[:one_time_password]
    fill_in "claim-one-time-password-field", with: otp_in_mail_sent
    click_on "Confirm"
  end
end
