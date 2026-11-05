require "rails_helper"

RSpec.feature "Early years payment practitioner", :testing_persona do
  let(:email_address) { "johndoe@example.com" }
  let(:journey_session) { Journeys::EarlyYearsPayment::Provider::Authenticated::Session.last }
  let(:mail) { ActionMailer::Base.deliveries.last }
  let(:magic_link) { mail.personalisation[:magic_link] }
  let!(:nursery) { create(:eligible_ey_provider, primary_key_contact_email_address: email_address, nursery_name: "Acme Nursery Ltd") }
  let(:claim) { Claim.last }

  scenario "Happy path" do
    create(:student_loans_data, nino: "PX321499A", date_of_birth: Date.new(1988, 2, 28), policy_name: Policies::FurtherEducationPayments)
    create(:journey_configuration, :early_years_payment_provider_authenticated)
    create(:journey_configuration, :early_years_payment_provider_start)
    create(
      :eligible_ey_provider,
      primary_key_contact_email_address: "johndoe@example.com",
      secondary_contact_email_address: "janedoe@example.com"
    )

    visit landing_page_path(Journeys::EarlyYearsPayment::Provider::Start.routing_name)
    click_link "Start now"
    fill_in "Enter your email address", with: "johndoe@example.com"
    click_on "Submit"

    visit ActionMailer::Base.deliveries.last.personalisation[:magic_link]
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
    choose "Yes"
    click_button "Continue"
    choose "No"
    click_button "Continue"
    fill_in "claim-practitioner-email-address-field", with: "practitioner@example.com"
    click_button "Continue"
    fill_in "claim-provider-contact-name-field", with: "John Doe"
    click_button "Accept and send"

    page.reset!

    create(:journey_configuration, :early_years_payment_practitioner)

    visit "/early-years-payment-practitioner/landing-page"
    expect(page).to have_text "Complete a claim for an early years"
    click_link "Start now"

    expect(page).to have_content "Enter your claim reference"
    fill_in "Enter your claim reference", with: claim.reference
    click_button "Submit"

    mock_one_login_auth

    expect(page).to have_content "Sign in with GOV.UK One Login"
    click_on "Continue"

    expect(page).to have_content "You’ve successfully signed in to GOV.UK One Login"
    click_on "Continue"

    idv_with_one_login

    expect(page).to have_content "You’ve successfully proved your identity with GOV.UK One Login"
    click_on "Continue"

    expect(page.title).to have_text("How we will use your information")
    expect(page).to have_content("How we will use your information")
    click_on "Continue"

    expect(page).to have_content("Personal details")
    expect(page).to have_content("Enter your National Insurance number")
    fill_in "National Insurance number", with: "PX321499A " # deliberate trailing space
    click_on "Continue"

    expect(page.title).to have_text("What is your home address?")
    expect(page).to have_content("What is your home address?")
    click_on("Enter your address manually")

    expect(page.title).to have_text("What is your address?")
    expect(page).to have_content("What is your address?")
    fill_in "House number or name", with: "57"
    fill_in "Building and street", with: "Walthamstow Drive"
    fill_in "Town or city", with: "Derby"
    fill_in "County", with: "City of Derby"
    fill_in "Postcode", with: "DE22 4BS"
    click_on "Continue"

    rest_of_the_journey

    ey_provider = claim.eligibility.eligible_ey_provider

    expect(
      ey_provider.primary_key_contact_email_address
    ).not_to have_received_email("b9bdff56-c0f7-4967-924d-2f9e65c77fa5")
  end

  scenario "Happy path - with postcode lookup" do
    create(:student_loans_data, nino: "PX321499A", date_of_birth: Date.new(1988, 2, 28), policy_name: Policies::FurtherEducationPayments)
    create(:journey_configuration, :early_years_payment_provider_authenticated)
    create(:journey_configuration, :early_years_payment_provider_start)
    create(
      :eligible_ey_provider,
      primary_key_contact_email_address: "johndoe@example.com",
      secondary_contact_email_address: "janedoe@example.com"
    )

    visit landing_page_path(Journeys::EarlyYearsPayment::Provider::Start.routing_name)
    click_link "Start now"
    fill_in "Enter your email address", with: "johndoe@example.com"
    click_on "Submit"

    visit ActionMailer::Base.deliveries.last.personalisation[:magic_link]
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
    choose "Yes"
    click_button "Continue"
    choose "No"
    click_button "Continue"
    fill_in "claim-practitioner-email-address-field", with: "practitioner@example.com"
    click_button "Continue"
    fill_in "claim-provider-contact-name-field", with: "John Doe"
    click_button "Accept and send"

    create(:journey_configuration, :early_years_payment_practitioner)

    visit "/early-years-payment-practitioner/find-reference?skip_landing_page=true&email=practitioner@example.com"
    expect(page).to have_content "Enter your claim reference"
    fill_in "Enter your claim reference", with: claim.reference
    click_button "Submit"

    mock_one_login_auth

    expect(page).to have_content "Sign in with GOV.UK One Login"
    click_on "Continue"

    expect(page).to have_content "You’ve successfully signed in to GOV.UK One Login"
    click_on "Continue"

    idv_with_one_login

    expect(page).to have_content "You’ve successfully proved your identity with GOV.UK One Login"
    click_on "Continue"

    expect(page.title).to have_text("How we will use your information")
    expect(page).to have_content("How we will use your information")
    click_on "Continue"

    expect(page).to have_content("Personal details")
    expect(page).to have_content("Enter your National Insurance number")
    fill_in "National Insurance number", with: "PX321499A " # deliberate trailing space
    click_on "Continue"

    expect(page.title).to have_text("What is your home address?")
    expect(page).to have_content("What is your home address?")

    stub_search_places_index(claim: OpenStruct.new(postcode: "SO16 9FX"))

    expect(page).to have_content("What is your home address?")
    fill_in "Postcode", with: "SO16 9FX"
    click_on "Search"

    expect(page.title).to have_text("What is your home address?")
    expect(page).to have_content("What is your home address?")
    expect(page).to have_text "Flat 1, Millbrook Tower, Windermere Avenue, Southampton, SO16 9FX"
    expect(page).to have_text "Flat 10, Millbrook Tower, Windermere Avenue, Southampton, SO16 9FX"
    expect(page).to have_text "Flat 11, Millbrook Tower, Windermere Avenue, Southampton, SO16 9FX"
    choose "Flat 1, Millbrook Tower, Windermere Avenue, Southampton, SO16 9FX"
    click_on "Continue"

    rest_of_the_journey
  end

  scenario "Happy path - with alt idv failure" do
    create(:student_loans_data, nino: "PX321499A", date_of_birth: Date.new(1988, 2, 28), policy_name: Policies::FurtherEducationPayments)
    create(:journey_configuration, :early_years_payment_provider_authenticated)
    create(:journey_configuration, :early_years_payment_provider_start)
    create(
      :eligible_ey_provider,
      primary_key_contact_email_address: "johndoe@example.com",
      secondary_contact_email_address: "janedoe@example.com"
    )

    visit landing_page_path(Journeys::EarlyYearsPayment::Provider::Start.routing_name)
    click_link "Start now"
    fill_in "Enter your email address", with: "johndoe@example.com"
    click_on "Submit"

    visit ActionMailer::Base.deliveries.last.personalisation[:magic_link]
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
    choose "Yes"
    click_button "Continue"
    choose "No"
    click_button "Continue"
    fill_in "claim-practitioner-email-address-field", with: "practitioner@example.com"
    click_button "Continue"
    fill_in "claim-provider-contact-name-field", with: "John Doe"
    click_button "Accept and send"

    create(:journey_configuration, :early_years_payment_practitioner)

    visit "/early-years-payment-practitioner/find-reference?skip_landing_page=true&email=practitioner@example.com"
    expect(page).to have_content "Enter your claim reference"
    fill_in "Enter your claim reference", with: claim.reference
    click_button "Submit"

    mock_one_login_auth

    expect(page).to have_content "Sign in with GOV.UK One Login"
    click_on "Continue"

    expect(page).to have_content "You’ve successfully signed in to GOV.UK One Login"
    click_on "Continue"

    idv_with_one_login_with_return_codes

    expect(page).to have_content(
      "We have not been able to confirm your identity via GOV.UK One Login"
    )
    expect(page).to have_content(
      "We’ll use your personal details to confirm who you are."
    )

    click_on "Continue"

    expect(page).to have_content("How we will use your information")
    click_on "Continue"

    fill_in "First name(s)", with: "Jo"
    fill_in "Last name", with: "Bloggs"
    click_on "Continue"

    fill_in "Day", with: "28"
    fill_in "Month", with: "2"
    fill_in "Year", with: "1988"
    click_on "Continue"

    fill_in "National Insurance number", with: "PX321499A " # deliberate trailing space
    click_on "Continue"

    expect(page.title).to have_text("What is your home address?")
    expect(page).to have_content("What is your home address?")

    stub_search_places_index(claim: OpenStruct.new(postcode: "SO16 9FX"))

    expect(page).to have_content("What is your home address?")
    fill_in "Postcode", with: "SO16 9FX"
    click_on "Search"

    expect(page.title).to have_text("What is your home address?")
    expect(page).to have_content("What is your home address?")
    expect(page).to have_text "Flat 1, Millbrook Tower, Windermere Avenue, Southampton, SO16 9FX"
    expect(page).to have_text "Flat 10, Millbrook Tower, Windermere Avenue, Southampton, SO16 9FX"
    expect(page).to have_text "Flat 11, Millbrook Tower, Windermere Avenue, Southampton, SO16 9FX"
    choose "Flat 1, Millbrook Tower, Windermere Avenue, Southampton, SO16 9FX"
    click_on "Continue"

    expect(page.title).to have_text("What is your personal email address?")
    expect(page).to have_content("What is your personal email address?")
    fill_in "What is your personal email address?", with: "johndoe@example.com"
    click_on "Continue"

    expect(page).to have_content("Enter the 6-digit passcode")
    mail = ActionMailer::Base.deliveries.last
    otp_in_mail_sent = mail.personalisation[:one_time_password]
    fill_in "claim-one-time-password-field", with: otp_in_mail_sent
    click_on "Confirm"

    expect(page).to have_content("Can we use your mobile number to contact you?")
    choose "No"
    click_on "Continue"

    expect(page).to have_text("Enter the bank account details your salary is paid into")
    fill_in "Name on the account", with: "Jo Bloggs"
    fill_in "Sort code", with: "123456"
    fill_in "Account number", with: "87654321"
    click_on "Continue"

    expect(page).to have_text(
      "How is your gender recorded on your employer’s payroll system?"
    )
    choose "Female"
    click_on "Continue"

    expect(page).to have_content("Check your answers before submitting this claim")
    perform_enqueued_jobs { click_on "Accept and send" }

    ey_provider = claim.eligibility.eligible_ey_provider

    expect(ey_provider.primary_key_contact_email_address).to have_received_email(
      "b9bdff56-c0f7-4967-924d-2f9e65c77fa5",
      claim_reference: claim.reference,
      provider_name: "John Doe",
      practitioner_full_name: "Jo Bloggs",
      practitioner_first_name: "Jo",
      verification_url: Journeys::EarlyYearsPayment::Provider::AlternativeIdv.verification_url(claim)
    )
  end

  def rest_of_the_journey
    expect(page.title).to have_text("What is your personal email address?")
    expect(page).to have_content("What is your personal email address?")
    fill_in "What is your personal email address?", with: "johndoe@example.com"
    click_on "Continue"

    expect(page).to have_content("Enter the 6-digit passcode")
    mail = ActionMailer::Base.deliveries.last
    otp_in_mail_sent = mail.personalisation[:one_time_password]
    fill_in "claim-one-time-password-field", with: otp_in_mail_sent
    click_on "Confirm"

    expect(page).to have_content("Can we use your mobile number to contact you?")
    choose "No"
    click_on "Continue"

    expect(page).to have_text("Enter the bank account details your salary is paid into")
    fill_in "Name on the account", with: "Jo Bloggs"
    fill_in "Sort code", with: "123456"
    fill_in "Account number", with: "87654321"
    click_on "Continue"

    expect(page).to have_text(
      "How is your gender recorded on your employer’s payroll system?"
    )
    choose "Female"
    click_on "Continue"

    expect(page).to have_content("Check your answers before submitting this claim")
    expect do
      perform_enqueued_jobs { click_on "Accept and send" }
    end.to not_change { Claim.count }
      .and not_change { Policies::EarlyYearsPayments::Eligibility.count }
      .and not_change { claim.reload.reference }
      .and change { ActionMailer::Base.deliveries.count }.by(1)

    expect(claim.eligibility.practitioner_claim_started_at).to be_present
    expect(claim.reload.submitted_at).to be_present
    expect(claim.student_loan_plan).to eq "plan_1"

    # check answers were saved on the claim
    expect(claim.reload.national_insurance_number).to eq "PX321499A"

    expect(page).to have_content("Claim submitted")
    expect(page).to have_content("we’ll check with Acme Nursery Ltd")
  end
end
