require "rails_helper"

RSpec.feature "Early years payment practitioner" do
  let(:email_address) { "johndoe@example.com" }
  let(:journey_session) { Journeys::EarlyYearsPayment::Provider::Authenticated::Session.last }
  let(:mail) { ActionMailer::Base.deliveries.last }
  let(:magic_link) { mail.personalisation[:magic_link] }
  let!(:nursery) { create(:eligible_ey_provider, primary_key_contact_email_address: email_address, nursery_name: "Acme Nursery Ltd") }
  let(:claim) { Claim.last }

  scenario "fails OL idv" do
    when_student_loan_data_exists
    when_early_years_payment_provider_authenticated_journey_submitted
    when_early_years_payment_practitioner_journey_configuration_exists

    visit "/early-years-payment-practitioner/find-reference?skip_landing_page=true&email=practitioner@example.com"
    expect(page).to have_content "Enter your claim reference"
    fill_in "Enter your claim reference", with: claim.reference
    click_button "Submit"

    expect(page.title).to have_text("How we’ll process your claim")
    expect(page).to have_content("How we’ll process your claim")
    click_on "Continue"

    mock_one_login_auth

    expect(page).to have_content "Sign in with GOV.UK One Login"
    click_on "Continue"

    mock_one_login_idv_with_return_codes

    expect(page).to have_content "You’ve successfully signed in to GOV.UK One Login"
    click_on "Continue"

    expect(page).to have_content "We cannot progress your application"
    expect(page).not_to have_button "Continue"
  end
end
