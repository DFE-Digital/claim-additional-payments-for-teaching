require "rails_helper"

RSpec.feature "Provider verifying claims" do
  before do
    #create(:journey_configuration, :further_education_payments_provider)
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

    claim_link = "/further-education-payments/verify-claim/#{claim.id}"

    visit claim_link

    click_on "Start now"

    expect(page).to have_text("You do not have access to verify claims for this organisation")

    # Attempt to skip to authorised page
    visit "/further-education-payments/third_parties/claims/#{claim.id}/verifications/new"

    expect(page).to have_text("You do not have access to verify claims for this organisation")
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
      "claim-verifier"
    )

    claim_link = "/further-education-payments/verify-claim/#{claim.id}"

    visit claim_link

    click_on "Start now"

    expect(page).to have_text "Verify claim form"
  end
end
