require "rails_helper"

RSpec.describe "Early years payment provider - Alternative IDV" do
  it "allows a provider to verify a practitioner's identity" do
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
        nursery_urn: nursery.urn
      }
    )

    idv_url = Journeys::EarlyYearsPayment::Provider::AlternativeIdv.verification_url(claim)

    visit idv_url

    expect(page).to have_content("Employment check needed for this claim")
    click_on "Start now"

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
      expect(table_row("Sort code")).to have_content "001001"
      expect(table_row("Account number")).to have_content "00000000"

      choose "Yes"
    end

    fill_in "Enter their personal email address", with: "edna.k@gmail.com"
    click_on "Continue"

    expect(page).to have_content "Employment Check"

    expect(summary_row("Date of birth")).to have_content("1 January 1970")
    expect(summary_row("Postcode")).to have_content("TE57 1NG")
    expect(summary_row("National Insurance number")).to have_content("QQ123456C")
    expect(summary_row("Bank details match")).to have_content("Yes")
    expect(summary_row("Email address")).to have_content("edna.k@gmail.com")

    check "To the best of my knowledge, I confirm that the information " \
      "provided in this form is correct"

    click_on "Confirm and send"

    expect(page).to have_content "Employment check complete"
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
        nursery_urn: nursery.urn
      }
    )

    idv_url = Journeys::EarlyYearsPayment::Provider::AlternativeIdv.verification_url(claim)

    visit idv_url

    expect(page).to have_content("Employment check needed for this claim")
    click_on "Start now"

    expect(page).to have_content(
      "Does Springfield Nursery employ Snake Jailbird?"
    )
    choose "No"
    click_on "Continue"

    expect(page).to have_content(
      "You've told us this applicant does not work at Springfield Nursery"
    )
  end

  def table_row(claim_reference)
    find("table tbody tr", text: claim_reference)
  end

  def summary_row(label)
    find("div.govuk-summary-list__row", text: label)
  end
end
