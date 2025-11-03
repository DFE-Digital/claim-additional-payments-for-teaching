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

            journey_session.answers.alternative_idv_completed!

            true
          end

          private

          def change_path(slug)
            Rails.application.routes.url_helpers.claim_path(
              journey.routing_name,
              slug,
              change: "check-answers"
            )
          end
        end
      end
    end
  end
end
