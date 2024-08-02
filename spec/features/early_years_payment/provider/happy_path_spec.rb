require "rails_helper"

RSpec.feature "Early years payment provider" do
  scenario "happy path claim" do
    when_early_years_payment_provider_journey_configuration_exists

    visit landing_page_path(Journeys::EarlyYearsPayment::Provider::ROUTING_NAME)
    click_link "Start now"

    expect(page.title).to have_text(I18n.t("early_years_payment_provider.forms.email_address.question"))
    expect(page).to have_content("Enter your email address")
    fill_in "Email address", with: "johndoe@example.com"
    click_on "Submit"

    expect(page.title).to have_text(I18n.t("early_years_payment_provider.check_your_email_page.title"))
    expect(page).to have_content("Check your email")
    expect(page).to have_content("We have sent an email to johndoe@example.com")

    mail = ActionMailer::Base.deliveries.last
    mail_personalisation = mail[:personalisation].unparsed_value
    expect(mail_personalisation[:one_time_password]).to match(/\A\d{6}\Z/)

    # TODO - uncomment below when magic link functionality in place
    # expect(page).to have_content("Declaration of Employee Consent")
    # check "I confirm that I have obtained consent from my employee and have provided them with the relevant privacy notice."
    # click_button "Continue"
  end

  scenario "send another link"

  scenario "enter another email address"
end
