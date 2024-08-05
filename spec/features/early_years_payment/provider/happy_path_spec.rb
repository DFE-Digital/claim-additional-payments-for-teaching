require "rails_helper"

RSpec.feature "Early years payment provider" do
  let(:journey_session) { Journeys::EarlyYearsPayment::Provider::Session.last }
  let(:mail) { ActionMailer::Base.deliveries.last }
  let(:magic_link) { mail[:personalisation].unparsed_value[:magic_link] }

  scenario "happy path claim" do
    when_early_years_payment_provider_journey_configuration_exists

    visit landing_page_path(Journeys::EarlyYearsPayment::Provider::ROUTING_NAME)
    click_link "Start now"

    expect(page.title).to have_text(I18n.t("early_years_payment_provider.forms.email_address.question"))
    expect(page).to have_content("Enter your email address")
    fill_in "Email address", with: "johndoe@example.com"
    click_on "Submit"

    expect(page.title).to have_text(I18n.t("early_years_payment_provider.check_your_email_page.title"))
    within ".govuk-notification-banner--success" do
      expect(page).to have_content("Email sent to johndoe@example.com")
    end
    expect(page).to have_content("Check your email")
    expect(page).to have_content("We have sent an email to johndoe@example.com")

    expect(mail.to).to eq ["johndoe@example.com"]
    expect(magic_link).to match(/\?code=\d{6}\Z/)

    visit magic_link
    expect(journey_session.reload.answers.email_verified).to be true
    expect(page).to have_content("Declaration of Employee Consent")
    check "I confirm that I have obtained consent from my employee and have provided them with the relevant privacy notice."
    click_button "Continue"
  end

  scenario "enter another email address" do
    when_early_years_payment_provider_journey_configuration_exists

    visit landing_page_path(Journeys::EarlyYearsPayment::Provider::ROUTING_NAME)
    click_link "Start now"

    fill_in "Email address", with: "johndoe@example.com"
    click_on "Submit"
    click_on "enter another email address"

    fill_in "Email address", with: "janedoe@example.com"
    click_on "Submit"

    expect(page).to have_content("We have sent an email to janedoe@example.com")

    expect(mail.to).to eq ["janedoe@example.com"]
  end
end
