module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class ClaimantEmploymentCheckDeclarationForm < BaseForm
          include Rails.application.routes.url_helpers

          attribute :provider_verification_claimant_employment_check_declaration, :boolean

          validates :provider_verification_claimant_employment_check_declaration,
            presence: {
              message: "Check the box once you have read the declaration"
            }

          def employment_status_rows
            [
              {
                key: {
                  text: "Does #{provider_name} employ #{claimant_name}?"
                },
                value: {
                  text: I18n.t(
                    eligibility.provider_verification_claimant_employed_by_college,
                    scope: :boolean
                  )
                },
                actions: [
                  {
                    href: edit_further_education_payments_providers_claim_verification_path(
                      claim,
                      slug: "claimant_employed_by_college"
                    ),
                    visually_hidden_text: "Change whether #{claimant_name} is employed by #{provider_name}"
                  }
                ]
              }
            ]
          end

          def personal_details_rows
            [
              {
                key: {
                  text: "Date of birth"
                },
                value: {
                  text: eligibility.provider_verification_claimant_date_of_birth&.strftime("%-d %B %Y")
                },
                actions: [
                  {
                    href: edit_further_education_payments_providers_claim_verification_path(
                      claim,
                      slug: "claimant_personal_details"
                    ),
                    visually_hidden_text: "Change #{claimant_name}'s date of birth"
                  }
                ]
              },
              {
                key: {
                  text: "Postcode"
                },
                value: {
                  text: eligibility.provider_verification_claimant_postcode
                },
                actions: [
                  {
                    href: edit_further_education_payments_providers_claim_verification_path(
                      claim,
                      slug: "claimant_personal_details"
                    ),
                    visually_hidden_text: "Change #{claimant_name}'s postcode"
                  }
                ]
              },
              {
                key: {
                  text: "National Insurance number"
                },
                value: {
                  text: eligibility.provider_verification_claimant_national_insurance_number
                },
                actions: [
                  {
                    href: edit_further_education_payments_providers_claim_verification_path(
                      claim,
                      slug: "claimant_personal_details"
                    ),
                    visually_hidden_text: "Change #{claimant_name}'s National Insurance number"
                  }
                ]
              },
              {
                key: {
                  text: "Bank details match"
                },
                value: {
                  text: I18n.t(
                    eligibility.provider_verification_claimant_bank_details_match,
                    scope: :boolean
                  )
                },
                actions: [
                  {
                    href: edit_further_education_payments_providers_claim_verification_path(
                      claim,
                      slug: "claimant_personal_details"
                    ),
                    visually_hidden_text: "Change whether #{claimant_name}'s bank details match"
                  }
                ]
              },
              {
                key: {
                  text: "Work email"
                },
                value: {
                  text: eligibility.provider_verification_claimant_email
                },
                actions: [
                  {
                    href: edit_further_education_payments_providers_claim_verification_path(
                      claim,
                      slug: "claimant_personal_details"
                    ),
                    visually_hidden_text: "Change #{claimant_name}'s work email"
                  }
                ]
              }
            ]
          end
        end
      end
    end
  end
end
