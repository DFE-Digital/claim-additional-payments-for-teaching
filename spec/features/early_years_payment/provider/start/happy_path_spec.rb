require "rails_helper"

RSpec.feature "Early years payment provider" do
  let(:mail) { ActionMailer::Base.deliveries.last }
  let(:magic_link) { mail.personalisation[:magic_link] }

  def number_of_emails_sent
    ActionMailer::Base.deliveries.count { |mail| mail.to == ["johndoe@example.com"] }
  end

  scenario "start - enter email, get magic link" do
    when_early_years_payment_provider_start_journey_configuration_exists
    when_eligible_ey_provider_exists

    visit guidance_path(Journeys::EarlyYearsPayment::Provider::Start::ROUTING_NAME)
    click_link "Start now"

    # landing page
    expect(page).to have_text("Employee eligibility")
    click_link "Start now"

    expect(page.title).to have_text("Enter your email address")
    expect(page).to have_content("Enter your email address")
    fill_in "Enter your email address", with: "johndoe@example.com"
    click_on "Submit"

    expect(page.title).to have_text("Check your email")
    expect(page).to have_content("Check your email")
    expect(page).to have_content("We have sent an email to johndoe@example.com")
    expect(page).not_to have_css ".govuk-notification-banner--success"

    expect(mail.to).to eq ["johndoe@example.com"]
    expect(magic_link).to match(/\?code=\d{6}&/)
  end

  scenario "enter another email address" do
    when_early_years_payment_provider_start_journey_configuration_exists
    when_eligible_ey_provider_exists

    visit landing_page_path(Journeys::EarlyYearsPayment::Provider::Start::ROUTING_NAME)
    click_link "Start now"

    fill_in "Enter your email address", with: "johndoe@example.com"
    click_on "Submit"
    click_on "enter another email address"

    fill_in "Enter your email address", with: "janedoe@example.com"
    click_on "Submit"

    expect(page).to have_content("We have sent an email to janedoe@example.com")

    expect(mail.to).to eq ["janedoe@example.com"]
  end

  scenario "send another link" do
    when_early_years_payment_provider_start_journey_configuration_exists
    when_eligible_ey_provider_exists

    visit landing_page_path(Journeys::EarlyYearsPayment::Provider::Start::ROUTING_NAME)
    click_link "Start now"

    fill_in "Enter your email address", with: "johndoe@example.com"
    click_on "Submit"
    click_button "send another link"

    within ".govuk-notification-banner--success" do
      expect(page).to have_content("Email sent to johndoe@example.com")
    end

    expect(number_of_emails_sent).to eq 2

    click_button "send another link"

    within ".govuk-notification-banner--success" do
      expect(page).to have_content("Email sent to johndoe@example.com")
    end
    expect(number_of_emails_sent).to eq 3

    visit claim_path(Journeys::EarlyYearsPayment::Provider::Start::ROUTING_NAME, :claim)
    choose "Continue with the eligibility check that you have already started"
    click_on "Continue"

    expect(page.title).to have_text("Check your email")
    expect(page).to have_content("Check your email")
  end
end
