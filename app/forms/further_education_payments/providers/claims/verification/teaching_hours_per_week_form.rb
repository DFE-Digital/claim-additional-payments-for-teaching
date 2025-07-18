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
              end,
              message: ->(form, _) do
                "Enter how many hours they were timetabled to teach during " \
                "the #{form.claimant_term} term"
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

          def claimant_term
            year = claim.submitted_at.year

            autumn_start = Date.new(year, 9, 1)
            autumn_end = Date.new(year, 12, 31)
            spring_start = Date.new(year, 1, 1)
            spring_end = Date.new(year, 4, 12)
            summer_start = Date.new(year, 4, 13)
            summer_end = Date.new(year, 8, 31)

            case claim.submitted_at
            when spring_start..spring_end then "spring"
            when summer_start..summer_end then "summer"
            when autumn_start..autumn_end then "autumn"
            else raise "Unexpected date: #{claim.submitted_at}"
            end
          end
        end
      end
    end
  end
end
