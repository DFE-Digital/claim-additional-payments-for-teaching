require "rails_helper"

RSpec.feature "Provider verifying claims" do
  before do
    create(:journey_configuration, :further_education_payments_provider)
  end

  scenario "provider visits a claim without service access" do
    fe_provider = create(:school, :further_education, name: "Springfield A&M")

    claim = create(
      :claim,
      first_name: "Edna",
      surname: "Krabappel",
      date_of_birth: Date.new(1945, 7, 3),
      reference: "AB123456",
      created_at: DateTime.new(2024, 8, 1, 9, 0, 0)
    )

    create(
      :further_education_payments_eligibility,
      claim: claim,
      school: fe_provider
    )

    mock_dfe_sign_in_auth_session(
      provider: :dfe_fe_provider,
      auth_hash: {
        uid: "11111",
        extra: {
          raw_info: {
            organisation: {
              id: "22222",
              ukprn: fe_provider.ukprn
            }
          }
        }
      }
    )

    # https://github.com/DFE-Digital/login.dfe.public-api?tab=readme-ov-file#get-user-access-to-service
    stub_failed_dfe_sign_in_user_info_request(
      "11111",
      "22222",
      status: 404
    )

    claim_link = Journeys::FurtherEducationPayments::Provider::SlugSequence.verify_claim_url(claim)

    visit claim_link

    click_on "Start now"

    expect(page).to have_text("You do not have access to this service")

    expect(page).to have_text(
      "You can request access to verify retention payments for further education teachers using DfE Sign-in."
    )

    # Try to visit the restricted slug directly
    visit "/further-education-payments-provider/verify-claim"

    expect(page).to have_text("You do not have access to this service")

    expect(page).to have_text(
      "You can request access to verify retention payments for further education teachers using DfE Sign-in."
    )
  end

  scenario "provider visits a claim for the wrong organisation" do
    fe_provider = create(:school, :further_education, name: "Springfield A&M")

    other_provider = create(
      :school,
      :further_education,
      name: "Springfield Elementary"
    )

    claim = create(
      :claim,
      first_name: "Edna",
      surname: "Krabappel",
      date_of_birth: Date.new(1945, 7, 3),
      reference: "AB123456",
      created_at: DateTime.new(2024, 8, 1, 9, 0, 0)
    )

    create(
      :further_education_payments_eligibility,
      claim: claim,
      school: fe_provider
    )

    mock_dfe_sign_in_auth_session(
      provider: :dfe_fe_provider,
      auth_hash: {
        uid: "11111",
        extra: {
          raw_info: {
            organisation: {
              id: "22222",
              ukprn: other_provider.ukprn
            }
          }
        }
      }
    )

    stub_dfe_sign_in_user_info_request(
      "11111",
      "22222",
      "some-role"
    )

    claim_link = Journeys::FurtherEducationPayments::Provider::SlugSequence.verify_claim_url(claim)

    visit claim_link

    click_on "Start now"

    expect(page).to have_text(
      "The organisation you have used to log in to DfE Sign-in does not match the organisation in the claim."
    )

    # Try to visit the restricted slug directly
    visit "/further-education-payments-provider/verify-claim"

    expect(page).to have_text(
      "The organisation you have used to log in to DfE Sign-in does not match the organisation in the claim."
    )
  end

  scenario "provider visits claim with the wrong role" do
    fe_provider = create(:school, :further_education, name: "Springfield A&M")

    claim = create(
      :claim,
      first_name: "Edna",
      surname: "Krabappel",
      date_of_birth: Date.new(1945, 7, 3),
      reference: "AB123456",
      created_at: DateTime.new(2024, 8, 1, 9, 0, 0)
    )

    create(
      :further_education_payments_eligibility,
      claim: claim,
      school: fe_provider
    )

    mock_dfe_sign_in_auth_session(
      provider: :dfe_fe_provider,
      auth_hash: {
        uid: "11111",
        extra: {
          raw_info: {
            organisation: {
              id: "22222",
              ukprn: fe_provider.ukprn
            }
          }
        }
      }
    )

    stub_dfe_sign_in_user_info_request(
      "11111",
      "22222",
      "some-other-role"
    )

    claim_link = Journeys::FurtherEducationPayments::Provider::SlugSequence.verify_claim_url(claim)

    visit claim_link

    click_on "Start now"

    expect(page).to have_text(
      "You do not have access to verify claims for this organisation"
    )

    expect(page).to have_text(
      "contact an approver at your organisation to confirm your access rights"
    )

    # Try to visit the restricted slug directly
    visit "/further-education-payments-provider/verify-claim"

    expect(page).to have_text(
      "You do not have access to verify claims for this organisation"
    )
  end

  scenario "provider approves the claim" do
    fe_provider = create(:school, :further_education, name: "Springfield A&M")

    claim = create(
      :claim,
      first_name: "Edna",
      surname: "Krabappel",
      date_of_birth: Date.new(1945, 7, 3),
      reference: "AB123456",
      created_at: DateTime.new(2024, 8, 1, 9, 0, 0)
    )

    create(
      :further_education_payments_eligibility,
      claim: claim,
      school: fe_provider
    )

    mock_dfe_sign_in_auth_session(
      provider: :dfe_fe_provider,
      auth_hash: {
        uid: "11111",
        extra: {
          raw_info: {
            organisation: {
              id: "22222",
              ukprn: fe_provider.ukprn
            }
          }
        }
      }
    )

    stub_dfe_sign_in_user_info_request(
      "11111",
      "22222",
      Journeys::FurtherEducationPayments::Provider::CLAIM_VERIFIER_DFE_SIGN_IN_ROLE_CODE
    )

    claim_link = Journeys::FurtherEducationPayments::Provider::SlugSequence.verify_claim_url(claim)

    visit claim_link

    click_on "Start now"

    expect(page).to have_text "Review a financial incentive payment claim"
    # The text generated by the dl tag doesn not include a space between the
    # label and value (displays as expected in browser).
    expect(page).to have_text "Claim referenceAB123456"
    expect(page).to have_text "Claimant nameEdna Krabappel"
    expect(page).to have_text "Claimant date of birth3 July 1945"
    # FIXME RL enable this test once we've added the TRN to the eligibility
    # expect(page).to have_text "Claimant teacher reference number (TRN)1234567"
    expect(page).to have_text "Claim date1 August 2024"

    check "To the best of my knowledge, I confirm that the information provided in this form is correct."

    click_on "Submit"

    expect(page).to have_content "Verification complete"
    expect(page).to have_text "Claim reference number AB123456"
  end

  scenario "provider visits the landing page" do
    visit(
      Journeys::FurtherEducationPayments::Provider::SlugSequence.start_page_url
    )

    expect(page).to have_text "You cannot access this service from DfE Sign-in"
  end
end