require "rails_helper"

RSpec.feature "Early years payment provider" do
  let(:email_address) { "johndoe@example.com" }
  let(:mail) { ActionMailer::Base.deliveries.last }
  let(:magic_link) { mail.personalisation[:magic_link] }
  let!(:nursery) { create(:eligible_ey_provider, primary_key_contact_email_address: email_address) }

  scenario "changing answers on the check-your-answers page" do
    when_early_years_payment_provider_authenticated_journey_configuration_exists
    when_early_years_payment_provider_start_journey_completed
    when_early_years_payment_provider_authenticated_journey_ready_to_submit

    click_link "Change employer’s paye reference number"
    expect(page).to have_content("What is #{nursery.nursery_name}’s employer PAYE reference?")
    fill_in "claim-paye-reference-field", with: "123/A"
    click_button "Continue"

    expect(page.current_path).to eq "/early-years-payment-provider/check-your-answers"
  end

  scenario "changing answers on the check-your-answers page that impacts journey" do
    when_early_years_payment_provider_authenticated_journey_configuration_exists
    when_early_years_payment_provider_start_journey_completed

    nursery = EligibleEyProvider.last || create(:eligible_ey_provider, primary_key_contact_email_address: "johndoe@example.com")

    visit magic_link
    check "I confirm that I’ve obtained consent from my employee and have provided them with the relevant privacy notice."
    click_button "Continue"

    choose nursery.nursery_name
    click_button "Continue"

    fill_in "claim-paye-reference-field", with: "123/123456SE90"
    click_button "Continue"

    fill_in "First name", with: "Bobby"
    fill_in "Last name", with: "Bobberson"
    click_button "Continue"

    date = Date.yesterday
    fill_in("Day", with: date.day)
    fill_in("Month", with: date.month)
    fill_in("Year", with: date.year)
    click_button "Continue"

    choose "Permanent"
    click_button "Continue"

    expect(page).to have_content "most of their time in their job working directly with children?"
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content "work in early years between"
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content "previous role in an early years setting involve mostly working directly with children?"
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content "Select the contract type"
    choose "casual or temporary"
    click_button "Continue"

    fill_in "claim-practitioner-email-address-field", with: "practitioner@example.com"
    click_button "Continue"

    expect(page).to have_content "Check your answers before submitting this claim"
    click_link "Change employee’s previous role in an early years setting involved working mostly with children"

    expect(page).to have_content("previous role in an early years setting involve mostly working directly with children?")
    choose "No"
    click_button "Continue"

    expect(page).to have_content "Check your answers before submitting this claim"
    expect(page).not_to have_content "Contract type"
    click_link "Change employee’s previous role in an early years setting involved working mostly with children"

    expect(page).to have_content("previous role in an early years setting involve mostly working directly with children?")
    choose "Yes"
    click_button "Continue"

    expect(page).to have_content "Select the contract type"
    choose "casual or temporary"
    click_button "Continue"

    expect(page).to have_content "Check your answers before submitting this claim"
    expect(page).to have_content "Contract type"
  end
end
