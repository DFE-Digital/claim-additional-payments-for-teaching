module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class ContractedHoursForm < BaseForm
          attribute :provider_verification_teaching_hours_per_week, :string
          attribute :provider_verification_half_teaching_hours, :boolean
          attribute :provider_verification_subjects_taught, :boolean
          attribute(
            :provider_verification_contracted_hours_section_completed,
            :boolean
          )

          validates(
            :provider_verification_teaching_hours_per_week,
            included: {
              in: ->(form) do
                form.provider_verification_teaching_hours_per_week_options.map(&:id)
              end
            },
            allow_nil: :save_and_exit?
          )

          validates(
            :provider_verification_half_teaching_hours,
            included: {
              in: ->(form) do
                form.provider_verification_half_teaching_hours_options.map(&:id)
              end
            },
            allow_nil: :save_and_exit?
          )

          validates(
            :provider_verification_subjects_taught,
            included: {
              in: ->(form) do
                form.provider_verification_subjects_taught_options.map(&:id)
              end
            },
            allow_nil: :save_and_exit?
          )

          validates(
            :provider_verification_contracted_hours_section_completed,
            inclusion: {
              in: ->(form) { form.section_completed_options.map(&:id) }
            }
          )

          def provider_verification_teaching_hours_per_week_options
            [
              Form::Option.new(
                id: "more_than_12",
                name: "12 hours or more per week"
              ),
              Form::Option.new(
                id: "between_2_5_and_12",
                name: "2.5 hours or more but less than 12 hours per week"
              ),
              Form::Option.new(
                id: "less_than_2_5",
                name: "Less than 2.5 hours per week"
              )
            ]
          end

          def provider_verification_half_teaching_hours_options
            [
              Form::Option.new(id: true, name: "Yes"),
              Form::Option.new(id: false, name: "No")
            ]
          end

          def provider_verification_subjects_taught_options
            [
              Form::Option.new(id: true, name: "Yes"),
              Form::Option.new(id: false, name: "No")
            ]
          end

          def section_completed_options
            [
              Form::Option.new(id: true, name: "Yes"),
              Form::Option.new(
                id: false,
                name: "No, I want to come back to it later"
              )
            ]
          end

          def subjects_taught_descriptions
            claim.eligibility.courses_taught.map(&:description)
          end

          def save_and_exit?
            provider_verification_contracted_hours_section_completed == false
          end
        end
      end
    end
  end
end
