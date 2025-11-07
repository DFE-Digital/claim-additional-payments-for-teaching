module Journeys
  module EarlyYearsPayment
    module Provider
      module Authenticated
        class AnswersPresenter < BaseAnswersPresenter
          include ActionView::Helpers::TranslationHelper

          def claim_answers
            [].tap do |a|
              a << nursery
              a << paye_reference
              a << employee_name
              a << start_date
              a << provider_entered_contract_type
              a << child_facing_confirmation_given
              a << returner
              a << returner_worked_with_children if journey_session.answers.returning_within_6_months
              a << returner_contract_type if journey_session.answers.returner_worked_with_children
              a << employee_email_address
            end
          end

          private

          def nursery
            [
              "Employee’s workplace",
              EligibleEyProvider.find_by(urn: answers.nursery_urn).nursery_name,
              "current-nursery"
            ]
          end

          def paye_reference
            [
              "Employer’s PAYE reference number",
              answers.paye_reference,
              "paye-reference"
            ]
          end

          def employee_name
            [
              "Employee’s name",
              [answers.first_name, answers.surname].join(" "),
              "claimant-name"
            ]
          end

          def start_date
            [
              "Employee’s start date",
              answers.start_date.to_fs(:long_date),
              "start-date"
            ]
          end

          def provider_entered_contract_type
            [
              "Employee’s contract type",
              I18n.t(
                answers.provider_entered_contract_type,
                scope: %w[
                  early_years_payment_provider_authenticated
                  forms
                  contract_type
                  options
                ].join(".")
              ),
              "contract-type"
            ]
          end

          def child_facing_confirmation_given
            [
              "Confirmation that employee spends most of their time in their job working directly with children",
              (answers.child_facing_confirmation_given ? "Yes" : "No"),
              "child-facing"
            ]
          end

          def returner
            [
              "Confirmation that employee worked in an early years setting 6 months before the start date",
              (answers.returning_within_6_months ? "Yes" : "No"),
              "returner"
            ]
          end

          def returner_worked_with_children
            [
              "Employee’s previous role in an early years setting involved working mostly with children",
              (answers.returner_worked_with_children ? "Yes" : "No"),
              "returner-worked-with-children"
            ]
          end

          def returner_contract_type
            [
              "Contract type for previous role in an early years setting",
              answers.returner_contract_type,
              "returner-contract-type"
            ]
          end

          def employee_email_address
            [
              "Employee’s email address",
              answers.practitioner_email_address,
              "employee-email"
            ]
          end
        end
      end
    end
  end
end
