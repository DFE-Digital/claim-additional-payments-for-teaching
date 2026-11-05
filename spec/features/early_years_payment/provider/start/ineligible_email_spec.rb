require "rails_helper"

RSpec.feature "Early years payment provider", :testing_persona do
  scenario "entering an email address which is not on the whitelist" do
    create(:journey_configuration, :early_years_payment_provider_start)
    create(
      :eligible_ey_provider,
      primary_key_contact_email_address: "johndoe@example.com",
      secondary_contact_email_address: "janedoe@example.com"
    )

    visit landing_page_path(Journeys::EarlyYearsPayment::Provider::Start.routing_name)
    click_link "Start now"

    expect(page.title).to have_text("Enter your email address")
    expect(page).to have_content("Enter your email address")
    fill_in "Enter your email address", with: "someoneelse@example.com"
    click_on "Submit"

    expect(page.title).to have_text("You do not have access to this service")
    expect(page).to have_content("You do not have access to this service")
    expect(page).to have_content("This email address does not have access to this service. Check the email address you entered and try again.")
    expect(page).not_to have_css ".govuk-notification-banner--success"
  end

  scenario "entering an email address which is not valid" do
    create(:journey_configuration, :early_years_payment_provider_start)
    create(
      :eligible_ey_provider,
      primary_key_contact_email_address: "johndoe@example.com",
      secondary_contact_email_address: "janedoe@example.com"
    )

    visit landing_page_path(Journeys::EarlyYearsPayment::Provider::Start.routing_name)
    click_link "Start now"

    expect(page.title).to have_text("Enter your email address")
    expect(page).to have_content("Enter your email address")
    fill_in "Enter your email address", with: "invalidemailaddress"
    click_on "Submit"

    expect(page.title).to have_text("You do not have access to this service")
    expect(page).to have_content("You do not have access to this service")
    expect(page).to have_content("This email address does not have access to this service. Check the email address you entered and try again.")
    expect(page).not_to have_css ".govuk-notification-banner--success"
  end
end
