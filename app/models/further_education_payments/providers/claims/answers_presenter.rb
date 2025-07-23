module FurtherEducationPayments
  module Providers
    module Claims
      class AnswersPresenter
        attr_reader :claim

        def initialize(claim:)
          @claim = claim
        end

        def role_and_experience
          array = []

          array << {
            key: {
              text: "Teaching responsibilities"
            },
            value: {
              text: I18n.t(
                claim.eligibility.provider_verification_teaching_responsibilities,
                scope: :boolean
              )
            }
          }

          array << {
            key: {
              text: "In first 5 years of FE teaching"
            },
            value: {
              text: I18n.t(
                claim.eligibility.provider_verification_in_first_five_years,
                scope: :boolean
              )
            }
          }

          array << {
            key: {
              text: "Teaching qualification"
            },
            value: {
              text: claim.eligibility.provider_verification_teaching_qualification.humanize
            }
          }

          array << {
            key: {
              text: "Type of contract"
            },
            value: {
              text: claim.eligibility.provider_verification_contract_type.humanize
            }
          }

          case claim.eligibility.provider_verification_contract_type
          when "fixed_term"
            array << {
              key: {
                text: "Contract covers full academic year"
              },
              value: {
                text: I18n.t(
                  claim.eligibility.provider_verification_contract_covers_full_academic_year,
                  scope: :boolean
                )
              }
            }
          when "variable_hours"
            array << {
              key: {
                text: "Variable hours in academic year"
              },
              value: {
                text: I18n.t(
                  claim.eligibility.provider_verification_contract_covers_full_academic_year,
                  scope: :boolean
                )
              }
            }
          end

          array
        end

        def performance_and_discipline
          [
            {
              key: {
                text: "Subject to performance measures"
              },
              value: {
                text: I18n.t(
                  claim.eligibility.provider_verification_performance_measures,
                  scope: :boolean
                )
              }
            },
            {
              key: {
                text: "Subject to disciplinary action"
              },
              value: {
                text: I18n.t(
                  claim.eligibility.provider_verification_disciplinary_action,
                  scope: :boolean
                )
              }
            }
          ]
        end

        def contracted_hours
          [
            {
              key: {
                text: "Timetabled hours per week"
              },
              value: {
                text: I18n.t(
                  claim.eligibility.provider_verification_teaching_hours_per_week,
                  scope: %w[
                    further_education_payments
                    providers
                    forms
                    teaching_hours_per_week
                    options
                  ]
                )
              }
            },
            {
              key: {
                text: "Teaches 16-19-year-olds or those with EHCP"
              },
              value: {
                text: I18n.t(
                  claim.eligibility.provider_verification_half_teaching_hours,
                  scope: :boolean
                )
              }
            },
            {
              key: {
                text: "Teaches approved qualification in #{subject_names_sentence}"
              },
              value: {
                text: I18n.t(
                  claim.eligibility.provider_verification_subjects_taught,
                  scope: :boolean
                )
              }
            }
          ]
        end

        private

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
