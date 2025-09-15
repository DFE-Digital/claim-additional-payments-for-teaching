require "rails_helper"

RSpec.feature "Provider verification access control" do
  let(:fe_provider) do
    create(
      :school,
      :further_education,
      name: "Springfield College",
      ukprn: "12345678"
    )
  end

  let(:other_fe_provider) do
    create(
      :school,
      :further_education,
      name: "Shelbyville College",
      ukprn: "87654321"
    )
  end

  let(:fe_provider_without_ukprn) do
    create(
      :school,
      :further_education,
      name: "Capital City High College",
      ukprn: nil
    )
  end

  let(:claim) do
    create(
      :claim,
      :submitted,
      :further_education,
      first_name: "Edna",
      surname: "Krabappel",
      reference: "AB123456",
      eligibility_attributes: {
        school: fe_provider,
        teacher_reference_number: "1234567"
      }
    )
  end

  let(:other_claim_1) do
    create(
      :claim,
      :submitted,
      :further_education,
      first_name: "Ned",
      surname: "Flanders",
      reference: "CD789012",
      eligibility_attributes: {
        school: other_fe_provider,
        teacher_reference_number: "7654321"
      }
    )
  end

  let(:other_claim_2) do
    create(
      :claim,
      :submitted,
      :further_education,
      first_name: "Ned",
      surname: "Flanders",
      reference: "CD789012",
      eligibility_attributes: {
        school: fe_provider_without_ukprn,
        teacher_reference_number: "7777777"
      }
    )
  end

  context "when user is not signed in" do
    it "redirects to sign-in page when trying to access verification" do
      visit(
        edit_further_education_payments_providers_claim_verification_path(claim)
      )

      expect(page).to have_current_path(
        new_further_education_payments_providers_session_path
      )
    end
  end

  context "when user's organization does not match claim's organization" do
    it "returns an error when trying to access claim from different organization" do
      mock_dfe_sign_in_auth_session(
        provider: :dfe_fe_provider,
        auth_hash: {
          uid: "11111",
          extra: {
            raw_info: {
              organisation: {
                id: "22222",
                ukprn: other_fe_provider.ukprn
              }
            }
          }
        }
      )

      stub_dfe_sign_in_user_info_request(
        "11111",
        "22222",
        Journeys::FurtherEducationPayments::Provider::CLAIM_VERIFIER_DFE_SIGN_IN_ROLE_CODE,
        user_type: "provider"
      )

      visit new_further_education_payments_providers_session_path
      click_on "Start now"

      visit(
        edit_further_education_payments_providers_claim_verification_path(claim)
      )

      expect(page).to(
        have_content(
          "The organisation you have used to log in to DfE Sign-in does not " \
          "match the organisation in the claim."
        )
      )
    end
  end

  context "when no ukprn is present" do
    # Unlikey scenario but if the user comes from DfE Sign-in without a UKPRN,
    # we don't want the claim scope to return any claims for schools without a
    # UKPRN.
    it "doesn't premit access to organization without ukprn" do
      mock_dfe_sign_in_auth_session(
        provider: :dfe_fe_provider,
        auth_hash: {
          uid: "11111",
          extra: {
            raw_info: {
              organisation: {
                id: "22222",
                ukprn: fe_provider_without_ukprn.ukprn
              }
            }
          }
        }
      )

      stub_dfe_sign_in_user_info_request(
        "11111",
        "22222",
        Journeys::FurtherEducationPayments::Provider::CLAIM_VERIFIER_DFE_SIGN_IN_ROLE_CODE,
        user_type: "provider"
      )

      visit new_further_education_payments_providers_session_path

      click_on "Start now"

      visit(
        edit_further_education_payments_providers_claim_verification_path(
          other_claim_2
        )
      )

      expect(page).to(
        have_content(
          "The organisation you have used to log in to DfE Sign-in does not " \
          "match the organisation in the claim."
        )
      )
    end
  end

  context "when user does not have service access" do
    it "shows authorization failure page with no service access reason" do
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
        status: 404,
        user_type: "provider"
      )

      visit new_further_education_payments_providers_session_path

      click_on "Start now"

      expect(page).to have_content("You do not have access to this service")

      expect(page).to have_link(
        "request access",
        href: "https://services.signin.education.gov.uk/request-service/teacherpayments/users/11111"
      )
    end
  end

  context "when user has incorrect role" do
    it "shows authorization failure page with incorrect role reason" do
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
        "incorrect_role_code",
        user_type: "provider"
      )

      visit new_further_education_payments_providers_session_path

      click_on "Start now"

      expect(page).to have_text(
        "You do not have access to verify claims for this organisation"
      )
    end
  end

  context "when the user was deleted" do
    it "shows authorization failure page with no service access" do
      create(
        :dfe_signin_user,
        dfe_sign_in_id: "11111",
        deleted_at: Time.zone.now
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
        Journeys::FurtherEducationPayments::Provider::CLAIM_VERIFIER_DFE_SIGN_IN_ROLE_CODE,
        user_type: "provider"
      )

      visit new_further_education_payments_providers_session_path

      click_on "Start now"

      expect(page).to have_content("You do not have access to this service")
    end
  end
end
