require "rails_helper"

RSpec.describe "Early years payment provider - Alternative IDV" do
  it "requires email verification code" do
    create(
      :journey_configuration,
      :early_years_payment_provider_alternative_idv
    )

    nursery = create(
      :eligible_ey_provider,
      nursery_name: "Springfield Nursery",
      primary_key_contact_email_address: "seymor.skinner@springfield-elementary.edu"
    )

    claim = create(
      :claim,
      policy: Policies::EarlyYearsPayments,
      onelogin_idv_at: 1.day.ago,
      identity_confirmed_with_onelogin: false,
      first_name: "Edna",
      surname: "Krabappel",
      eligibility_attributes: {
        nursery_urn: nursery.urn,
        alternative_idv_reference: "1234567890"
      }
    )

    idv_url = Journeys::EarlyYearsPayment::Provider::AlternativeIdv.verification_url(claim)

    visit idv_url

    expect(page).to have_content("Employment check needed for this claim")

    click_on "Start now"

    expect(page).to have_content(
      "We have sent an email to seymor.skinner@springfield-elementary.edu " \
      "with a 6-digit passcode"
    )

    fill_in "Enter the 6-digit passcode", with: "123456"
    click_on "Confirm"

    expect(page).to have_content("Enter a valid passcode")

    # Attempt to skip ahead

    visit "/early-years-payment-provider-alternative-idv/claimant-employed-by-nursery"

    expect(page.current_url).to end_with(
      "/early-years-payment-provider-alternative-idv/email-verification"
    )

    expect(page).to have_content(
      "We have sent an email to seymor.skinner@springfield-elementary.edu " \
      "with a 6-digit passcode"
    )

    visit "/early-years-payment-provider-alternative-idv/claimant-personal-details"

    expect(page.current_url).to end_with(
      "/early-years-payment-provider-alternative-idv/email-verification"
    )

    expect(page).to have_content(
      "We have sent an email to seymor.skinner@springfield-elementary.edu " \
      "with a 6-digit passcode"
    )
  end

  it "allows a provider to verify a practitioner's identity" do
    create(
      :journey_configuration,
      :early_years_payment_provider_alternative_idv
    )

    nursery = create(
      :eligible_ey_provider,
      nursery_name: "Springfield Nursery",
      primary_key_contact_email_address: "seymor.skinner@springfield-elementary.edu"
    )

    claim = create(
      :claim,
      policy: Policies::EarlyYearsPayments,
      onelogin_idv_at: 1.day.ago,
      identity_confirmed_with_onelogin: false,
      first_name: "Edna",
      surname: "Krabappel",
      bank_account_number: "00000000",
      bank_sort_code: "001001",
      banking_name: "Edna Krabappel",
      eligibility_attributes: {
        nursery_urn: nursery.urn,
        alternative_idv_reference: "1234567890"
      }
    )

    idv_url = Journeys::EarlyYearsPayment::Provider::AlternativeIdv.verification_url(claim)

    visit idv_url

    expect(page).to have_content("Employment check needed for this claim")

    perform_enqueued_jobs do
      click_on "Start now"
    end

    expect(page).to have_content(
      "We have sent an email to seymor.skinner@springfield-elementary.edu " \
      "with a 6-digit passcode"
    )

    mail = ActionMailer::Base.deliveries.last
    otp_in_mail_sent = mail.personalisation[:one_time_password]

    fill_in "Enter the 6-digit passcode", with: otp_in_mail_sent
    click_on "Confirm"

    expect(page).to have_content(
      "Does Springfield Nursery employ Edna Krabappel?"
    )
    choose "Yes"
    click_on "Continue"

    expect(page).to have_content("About Edna Krabappel")

    within_fieldset "Enter their date of birth" do
      fill_in "Day", with: 1
      fill_in "Month", with: 1
      fill_in "Year", with: 1970
    end

    fill_in "Enter their postcode", with: "TE57 1NG"

    fill_in "Enter their National Insurance number", with: "QQ123456C"

    within_fieldset "Do these bank details match what you have for Edna Krabappel" do
      expect(table_row("Name on the account")).to have_content "Edna Krabappel"
      expect(table_row("Sort code")).to have_content "00-10-01"
      expect(table_row("Account number")).to have_content "****0000"

      choose "Yes"
    end

    fill_in "Enter their personal email address", with: "edna.k@gmail.com"
    click_on "Continue"

    expect(page).to have_content "Employment check"

    expect(summary_row("Date of birth")).to have_content("1 January 1970")
    expect(summary_row("Postcode")).to have_content("TE57 1NG")
    expect(summary_row("National Insurance number")).to have_content("QQ123456C")
    expect(summary_row("Bank details match")).to have_content("Yes")
    expect(summary_row("Email address")).to have_content("edna.k@gmail.com")

    check "To the best of my knowledge, I confirm that the information " \
      "provided in this form is correct"

    click_on "Confirm and send"

    expect(page).to have_content "Employment check complete"

    eligibility = claim.reload.eligibility

    expect(
      eligibility.alternative_idv_claimant_employed_by_nursery
    ).to be true

    expect(
      eligibility.alternative_idv_claimant_date_of_birth
    ).to eq Date.new(1970, 1, 1)

    expect(
      eligibility.alternative_idv_claimant_postcode
    ).to eq "TE57 1NG"

    expect(
      eligibility.alternative_idv_claimant_national_insurance_number
    ).to eq "QQ123456C"

    expect(
      eligibility.alternative_idv_claimant_bank_details_match
    ).to be true

    expect(
      eligibility.alternative_idv_claimant_email
    ).to eq "edna.k@gmail.com"

    expect(
      eligibility.alternative_idv_claimant_employment_check_declaration
    ).to be true

    expect(eligibility.alternative_idv_completed_at).to be_present
  end

  it "allows the provider to reject a claim" do
    create(
      :journey_configuration,
      :early_years_payment_provider_alternative_idv
    )

    nursery = create(
      :eligible_ey_provider,
      nursery_name: "Springfield Nursery"
    )

    claim = create(
      :claim,
      policy: Policies::EarlyYearsPayments,
      onelogin_idv_at: 1.day.ago,
      identity_confirmed_with_onelogin: false,
      first_name: "Snake",
      surname: "Jailbird",
      bank_account_number: "00000000",
      bank_sort_code: "001001",
      banking_name: "Chester Turley",
      eligibility_attributes: {
        nursery_urn: nursery.urn,
        alternative_idv_reference: "1234567890"
      }
    )

    idv_url = Journeys::EarlyYearsPayment::Provider::AlternativeIdv.verification_url(claim)

    visit idv_url

    expect(page).to have_content("Employment check needed for this claim")

    perform_enqueued_jobs do
      click_on "Start now"
    end

    mail = ActionMailer::Base.deliveries.last
    otp_in_mail_sent = mail.personalisation[:one_time_password]

    fill_in "Enter the 6-digit passcode", with: otp_in_mail_sent
    click_on "Confirm"

    expect(page).to have_content(
      "Does Springfield Nursery employ Snake Jailbird?"
    )
    choose "No"
    click_on "Continue"

    expect(page).to have_content(
      "You’ve told us this applicant does not work at Springfield Nursery"
    )

    eligibility = claim.reload.eligibility

    expect(eligibility.alternative_idv_claimant_employed_by_nursery).to be false
    expect(eligibility.alternative_idv_completed_at).to be_present
  end

  it "doesn't allow the provider to verify a claim that has already been verified" do
    create(
      :journey_configuration,
      :early_years_payment_provider_alternative_idv
    )

    nursery = create(
      :eligible_ey_provider,
      nursery_name: "Springfield Nursery"
    )

    claim = create(
      :claim,
      policy: Policies::EarlyYearsPayments,
      onelogin_idv_at: 1.day.ago,
      identity_confirmed_with_onelogin: false,
      first_name: "Edna",
      surname: "Krabappel",
      bank_account_number: "00000000",
      bank_sort_code: "001001",
      banking_name: "Edna Krabappel",
      eligibility_attributes: {
        nursery_urn: nursery.urn,
        alternative_idv_completed_at: Time.zone.now,
        alternative_idv_reference: "1234567890"
      }
    )

    idv_url = Journeys::EarlyYearsPayment::Provider::AlternativeIdv.verification_url(claim)

    visit idv_url

    click_on "Start now"

    expect(page).to have_content(
      "An employment check has already been completed for this claim"
    )
  end

  it "informs the provider if the url is invalid" do
    create(
      :journey_configuration,
      :early_years_payment_provider_alternative_idv
    )

    stub_claim = OpenStruct.new(
      eligibility: OpenStruct.new(
        alternative_idv_reference: "invalid_reference"
      )
    )

    idv_url = Journeys::EarlyYearsPayment::Provider::AlternativeIdv.verification_url(
      stub_claim
    )

    visit idv_url

    click_on "Start now"

    expect(page).to have_content("We can’t find this claim")
  end

  def table_row(claim_reference)
    find("table tbody tr", text: claim_reference)
  end

  def summary_row(label)
    find("div.govuk-summary-list__row", text: label)
  end
end
