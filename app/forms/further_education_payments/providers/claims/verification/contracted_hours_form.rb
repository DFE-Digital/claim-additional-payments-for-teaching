module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class ContractedHoursForm < BaseForm
          attribute :provider_verification_teaching_hours_per_week, :string
          attribute :provider_verification_half_teaching_hours, :boolean
          attribute :provider_verification_subjects_taught, :boolean

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

          def subjects_taught_descriptions
            claim.eligibility.courses_taught.map(&:description)
          end
        end
      end
    end
  end
end
