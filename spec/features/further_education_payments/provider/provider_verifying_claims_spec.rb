require "rails_helper"

RSpec.feature "Provider verifying claims" do
  before do
    create(:journey_configuration, :further_education_payments_provider)
  end

  scenario "Provider without access visits email link" do
    fe_provider = create(:school, :further_education, name: "Springfield A&M")

    claim = create(
      :claim,
      first_name: "Edna",
      surname: "Krabappel",
      date_of_birth: Date.new(1945, 7, 3),
      reference: "AB123456",
      created_at: DateTime.new(2024, 8, 1, 9, 0, 0)
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
      "no-access-role-code"
    )

    claim_link = Journeys::FurtherEducationPayments::Provider::SlugSequence.verify_claim_url(claim)

    visit claim_link

    click_on "Start now"

    click_on "Sign in"

    expect(page).to have_text("You do not have access to verify claims for this organisation")

    # Attempt to skip to authorised page
    visit claim_path(journey: "further-education-payments-provider", slug: "verify-claim")

    expect(page).to have_button("Sign in")
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

    click_on "Sign in"

    expect(page).to have_text "Verify claim form"
  end
end
