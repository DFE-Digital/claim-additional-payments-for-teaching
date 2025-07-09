module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class CheckAnswersForm < BaseForm
          attribute :provider_verification_declaration, :boolean, default: false

          validates :provider_verification_declaration, acceptance: true

          delegate(
            :provider_verification_teaching_responsibilities,
            :provider_verification_in_first_five_years,
            :provider_verification_teaching_qualification,
            :provider_verification_contract_covers_full_academic_year,
            :provider_verification_contract_type,
            :provider_verification_taught_at_least_one_academic_term,
            :provider_verification_performance_measures,
            :provider_verification_disciplinary_action,
            :provider_verification_teaching_hours_per_week,
            :provider_verification_half_teaching_hours,
            :provider_verification_subjects_taught,
            to: :eligibility
          )

          def contract_type
            case provider_verification_contract_type
            when "fixed_term" then "Fixed-term"
            when "variable_hours" then "Variable hours"
            when "permanent" then "Permanent"
            else fail "Unknown contract type"
            end
          end

          def subject_names_sentence
            claim.eligibility.subjects_taught.map do |subject|
              I18n.t(
                subject,
                scope: %w[
                  further_education_payments
                  forms
                  subjects_taught
                  options
                ]
              )
            end.map(&:downcase).to_sentence
          end
        end
      end
    end
  end
end
