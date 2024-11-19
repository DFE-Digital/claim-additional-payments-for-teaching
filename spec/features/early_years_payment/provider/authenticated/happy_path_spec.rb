require "rails_helper"

RSpec.feature "Early years payment provider" do
  let(:email_address) { "johndoe@example.com" }
  let(:journey_session) { Journeys::EarlyYearsPayment::Provider::Authenticated::Session.last }
  let(:mail) { ActionMailer::Base.deliveries.last }
  let(:magic_link) { mail[:personalisation].unparsed_value[:magic_link] }
  let!(:nursery) { create(:eligible_ey_provider, primary_key_contact_email_address: email_address) }

  scenario "magic link onwards" do
    when_early_years_payment_provider_authenticated_journey_configuration_exists
    when_early_years_payment_provider_start_journey_completed

    visit magic_link
    expect(page).to have_content("Before you continue with your claim")
    expect(page.current_path).to eq "/early-years-payment-provider/consent"
    check "I confirm that I’ve obtained consent from my employee and have provided them with the relevant privacy notice."
    click_button "Continue"

    expect(journey_session.reload.answers.email_address).to be nil
    expect(journey_session.reload.answers.email_verified).to be nil
    expect(journey_session.reload.answers.provider_email_address).to eq email_address

    expect(page.current_path).to eq "/early-years-payment-provider/current-nursery"
    choose nursery.nursery_name
    click_button "Continue"

    expect(page.current_path).to eq "/early-years-payment-provider/paye-reference"
    expect(page).to have_content("What is #{nursery.nursery_name}’s employer PAYE reference?")
    fill_in "claim-paye-reference-field", with: "123/123456SE90"
    click_button "Continue"

    expect(page.current_path).to eq "/early-years-payment-provider/claimant-name"
    fill_in "First name", with: "Bobby"
    fill_in "Last name", with: "Bobberson"
    click_button "Continue"

    expect(page.current_path).to eq "/early-years-payment-provider/start-date"
    date = Date.yesterday
    fill_in("Day", with: date.day)
    fill_in("Month", with: date.month)
    fill_in("Year", with: date.year)
    click_button "Continue"

    expect(page.current_path).to eq "/early-years-payment-provider/child-facing"
    choose "Yes"
    click_button "Continue"

    expect(page.current_path).to eq "/early-years-payment-provider/returner"
    choose "No"
    click_button "Continue"
    expect(page.current_path).to eq "/early-years-payment-provider/employee-email"

    click_link "Back"
    expect(page.current_path).to eq "/early-years-payment-provider/returner"
    choose "Yes"
    click_button "Continue"

    expect(page.current_path).to eq "/early-years-payment-provider/returner-worked-with-children"
    choose "No"
    click_button "Continue"
    expect(page.current_path).to eq "/early-years-payment-provider/employee-email"

    click_link "Back"
    expect(page.current_path).to eq "/early-years-payment-provider/returner-worked-with-children"
    choose "Yes"
    click_button "Continue"

    expect(page.current_path).to eq "/early-years-payment-provider/returner-contract-type"
    choose "casual or temporary"
    click_button "Continue"
    expect(page.current_path).to eq "/early-years-payment-provider/employee-email"

    fill_in "claim-practitioner-email-address-field", with: "practitioner@example.com"
    click_button "Continue"

    expect(page.current_path).to eq "/early-years-payment-provider/check-your-answers"
    expect(page).to have_content("Check your answers before submitting this claim")
    fill_in "claim-provider-contact-name-field", with: "John Doe"

    expect do
      perform_enqueued_jobs { click_on "Accept and send" }
    end.to change { Claim.count }.by(1)
      .and change { Policies::EarlyYearsPayments::Eligibility.count }.by(1)
      .and change { ActionMailer::Base.deliveries.count }.by(2)

    expect(page.current_path).to eq claim_confirmation_path(Journeys::EarlyYearsPayment::Provider::Authenticated::ROUTING_NAME)

    claim = Claim.last
    expect(claim.provider_contact_name).to eq "John Doe"
    expect(page).to have_content(claim.reference)
    expect(claim.submitted_at).to be_nil
    expect(claim.eligibility.reload.provider_claim_submitted_at).to be_present
    expect(claim.eligibility.provider_email_address).to eq email_address
    expect(claim.eligibility.award_amount).to eq 1000
  end

  scenario "using magic link after having completed some of the journey" do
    when_early_years_payment_provider_authenticated_journey_configuration_exists
    when_early_years_payment_provider_start_journey_completed

    visit magic_link
    check "I confirm that I’ve obtained consent from my employee and have provided them with the relevant privacy notice."
    click_button "Continue"

    visit magic_link
    expect(page.current_path).to eq "/early-years-payment-provider/current-nursery"
  end
end
