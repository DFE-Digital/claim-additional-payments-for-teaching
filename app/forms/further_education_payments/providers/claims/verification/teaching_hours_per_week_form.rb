module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class TeachingHoursPerWeekForm < BaseForm
          attribute :provider_verification_teaching_hours_per_week, :string

          validates(
            :provider_verification_teaching_hours_per_week,
            included: {
              in: ->(form) do
                form.provider_verification_teaching_hours_per_week_options.map(&:id)
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
        end
      end
    end
  end
end
