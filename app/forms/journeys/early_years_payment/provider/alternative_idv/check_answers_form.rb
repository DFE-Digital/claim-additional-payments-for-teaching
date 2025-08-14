module Journeys
  module EarlyYearsPayment
    module Provider
      module AlternativeIdv
        class CheckAnswersForm < Form
          attribute :claimant_employment_check_declaration, :boolean, default: false

          validates(
            :claimant_employment_check_declaration,
            acceptance: {
              message: i18n_error_message(
                "claimant_employment_check_declaration.acceptance"
              )
            }
          )

          def claimant_name
            answers.claim.full_name
          end

          def nursery_name
            answers.nursery.nursery_name
          end

          def employment_status_rows
            [
              {
                key: {
                  text: "Does #{nursery_name} employ #{claimant_name}?"
                },
                value: {
                  text: I18n.t(answers.claimant_employed_by_nursery, scope: :boolean)
                },
                actions: [
                  {
                    href: change_path("claimant-employed-by-nursery")
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
                  text: I18n.l(answers.claimant_date_of_birth)
                },
                actions: [
                  {
                    href: change_path("claimant-personal-details")
                  }
                ]
              },
              {
                key: {
                  text: "Postcode"
                },
                value: {
                  text: answers.claimant_postcode
                },
                actions: [
                  {
                    href: change_path("claimant-personal-details")
                  }
                ]
              },
              {
                key: {
                  text: "National Insurance number"
                },
                value: {
                  text: answers.claimant_national_insurance_number
                },
                actions: [
                  {
                    href: change_path("claimant-personal-details")
                  }
                ]
              },
              {
                key: {
                  text: "Bank details match"
                },
                value: {
                  text: I18n.t(answers.claimant_bank_details_match, scope: :boolean)
                },
                actions: [
                  {
                    href: change_path("claimant-personal-details")
                  }
                ]
              },
              {
                key: {
                  text: "Email address"
                },
                value: {
                  text: answers.claimant_email
                },
                actions: [
                  {
                    href: change_path("claimant-personal-details")
                  }
                ]
              }
            ]
          end

          def save
            return false if invalid?

            journey_session.answers.assign_attributes(
              claimant_employment_check_declaration: claimant_employment_check_declaration
            )

            journey_session.save!

            answers.claim.eligibility.update!(
              alternative_idv_claimant_employed_by_nursery: answers.claimant_employed_by_nursery,
              alternative_idv_claimant_date_of_birth: answers.claimant_date_of_birth,
              alternative_idv_claimant_postcode: answers.claimant_postcode,
              alternative_idv_claimant_national_insurance_number: answers.claimant_national_insurance_number,
              alternative_idv_claimant_bank_details_match: answers.claimant_bank_details_match,
              alternative_idv_claimant_email: answers.claimant_email,
              alternative_idv_claimant_employment_check_declaration: claimant_employment_check_declaration,
              alternative_idv_completed_at: DateTime.current.utc
            )

            true
          end

          private

          def change_path(slug)
            Rails.application.routes.url_helpers.claim_path(
              journey::ROUTING_NAME,
              slug,
              change: "check-answers"
            )
          end
        end
      end
    end
  end
end
