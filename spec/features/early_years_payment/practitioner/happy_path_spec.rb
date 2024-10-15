require "rails_helper"

RSpec.feature "Early years payment practitioner" do
  let(:email_address) { "johndoe@example.com" }
  let(:journey_session) { Journeys::EarlyYearsPayment::Provider::Authenticated::Session.last }
  let(:mail) { ActionMailer::Base.deliveries.last }
  let(:magic_link) { mail[:personalisation].unparsed_value[:magic_link] }
  let!(:nursery) { create(:eligible_ey_provider, primary_key_contact_email_address: email_address) }
  let(:claim) { Claim.last }

  scenario "Happy path" do
    when_early_years_payment_provider_authenticated_journey_submitted
    when_early_years_payment_practitioner_journey_configuration_exists

    visit "/early-years-payment-practitioner/find-reference?skip_landing_page=true&email=practitioner@example.com"
    expect(page).to have_content "Enter your claim reference"
    fill_in "Claim reference number", with: claim.reference
    click_button "Submit"

    expect(page).to have_content "Sign in with GOV.UK One Login"
    click_on "Continue"

    expect(page).to have_content "You have successfully signed in to GOV.UK One Login"
    click_on "Continue"

    expect(page).to have_content "You have successfully proved your identity with GOV.UK One Login"
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

    expect(page).to have_content("Would you like to provide your mobile number?")
    choose "No"
    click_on "Continue"

    expect(page).to have_text(I18n.t("questions.account_details", bank_or_building_society: "personal bank account"))
    fill_in "Name on your account", with: "Jo Bloggs"
    fill_in "Sort code", with: "123456"
    fill_in "Account number", with: "87654321"
    click_on "Continue"

    expect(page).to have_text(I18n.t("forms.gender.questions.payroll_gender"))
    choose "Female"
    click_on "Continue"
    
    expect(page).to have_content("Check your answers before submitting this claim")
    expect do
        click_on "Accept and send"
    end.to change { Claim.count }.by(1)
    .and change { Policies::EarlyYearsPayments::Eligibility.count }.by(1)
  end
end
