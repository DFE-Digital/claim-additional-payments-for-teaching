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
                claim.eligibility.provider_verification_teaching_start_year_matches_claim,
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
                text: "Spend at least half timetabled teaching time teaching relevant courses"
              },
              value: {
                text: I18n.t(
                  claim.eligibility.provider_verification_half_timetabled_teaching_time,
                  scope: :boolean
                )
              }
            }
          ]
        end

        def claimant_not_employed_by_college?
          @claim.eligibility.claimant_not_employed_by_college?
        end

        def provider_name
          @claim.eligibility.school.name
        end

        def claimant_name
          @claim.full_name
        end

        def provider_verification_completed_at
          @claim.eligibility.provider_verification_completed_at
        end

        def teacher_reference_number
          @claim.eligibility.teacher_reference_number.presence || "Not provided"
        end

        delegate :reference, :submitted_at, to: :claim

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
