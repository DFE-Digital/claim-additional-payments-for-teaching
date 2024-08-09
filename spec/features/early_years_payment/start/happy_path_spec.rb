require "rails_helper"

RSpec.feature "Early years payment provider" do
  let(:journey_session) { Journeys::EarlyYearsPayment::Provider::Session.last }
  let(:mail) { ActionMailer::Base.deliveries.last }
  let(:magic_link) { mail[:personalisation].unparsed_value[:magic_link] }

  scenario "start - enter email, get magic link" do
    when_early_years_payment_start_journey_configuration_exists
    when_eligible_ey_provider_exists

    visit landing_page_path(Journeys::EarlyYearsPayment::Start::ROUTING_NAME)
    click_link "Start now"

    expect(page.title).to have_text("Enter your email address")
    expect(page).to have_content("Enter your email address")
    fill_in "Email address", with: "johndoe@example.com"
    click_on "Submit"

    expect(page.title).to have_text("Check your email")
    within ".govuk-notification-banner--success" do
      expect(page).to have_content("Email sent to johndoe@example.com")
    end
    expect(page).to have_content("Check your email")
    expect(page).to have_content("We have sent an email to johndoe@example.com")

    expect(mail.to).to eq ["johndoe@example.com"]
    expect(magic_link).to match(/\?code=\d{6}&/)
  end

  scenario "enter another email address" do
    when_early_years_payment_start_journey_configuration_exists
    when_eligible_ey_provider_exists

    visit landing_page_path(Journeys::EarlyYearsPayment::Start::ROUTING_NAME)
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
