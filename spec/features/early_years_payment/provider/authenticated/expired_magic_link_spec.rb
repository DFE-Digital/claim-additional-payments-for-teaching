require "rails_helper"

RSpec.feature "Early years payment provider" do
  let(:email_address) { "johndoe@example.com" }
  let(:journey_session) { Journeys::EarlyYearsPayment::Provider::Authenticated::Session.last }
  let(:mail) { ActionMailer::Base.deliveries.last }
  let(:magic_link) { mail.personalisation[:magic_link] }
  let!(:nursery) do
    create(
      :eligible_ey_provider,
      primary_key_contact_email_address: email_address,
      nursery_name: "Springfield Nursery"
    )
  end

  scenario "expired magic link" do
    travel(-20.minutes) do
      when_early_years_payment_provider_authenticated_journey_configuration_exists
      when_early_years_payment_provider_start_journey_completed
    end

    visit magic_link

    expect(journey_session.reload.answers.email_address).to eq nil
    expect(journey_session.reload.answers.email_verified).to be nil

    expect(page).to have_content("This link has expired")
    expect(page.current_path).to eq "/early-years-payment-provider/expired-link"

    click_link "Resend email"

    fill_in "Enter your email address", with: email_address
    click_button "Submit"

    expect(email_address).to have_received_email(
      ApplicationMailer::EARLY_YEARS_PAYMENTS[:CLAIM_PROVIDER_EMAIL_TEMPLATE_ID]
    )
  end

  scenario "attempting to resend expired magic link in different browser" do
    when_early_years_payment_provider_start_journey_configuration_exists
    when_early_years_payment_provider_authenticated_journey_configuration_exists

    # If the code isn't expected we show the expired link page.
    visit "/early-years-payment-provider/claim?code=383323&email=test@example.com"

    expect(page).to have_content("This link has expired")

    click_link "Resend email"

    fill_in "Enter your email address", with: email_address
    click_button "Submit"

    expect(email_address).to have_received_email(
      ApplicationMailer::EARLY_YEARS_PAYMENTS[:CLAIM_PROVIDER_EMAIL_TEMPLATE_ID]
    )
  end

  scenario "visiting the magic link twice" do
    when_early_years_payment_provider_authenticated_journey_configuration_exists
    when_early_years_payment_provider_start_journey_completed

    2.times do
      visit magic_link
    end

    check "I confirm that I’ve obtained consent from my employee and have " \
      "provided them with the relevant privacy notice."

    click_button "Continue"

    expect(page).to have_text(
      "Select the name of the nursery where your employee works"
    )

    expect(page).to have_content "Springfield Nursery"
  end
end
