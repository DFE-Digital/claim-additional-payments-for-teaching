module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class TeachingHoursPerWeekForm < BaseForm
          TEACHING_HOURS_PER_WEEK_OPTIONS = [
            Form::Option.new(
              id: "20_or_more_hours_per_week",
              name: "20 hours or more each week"
            ),
            Form::Option.new(
              id: "12_to_20_hours_per_week",
              name: "12 hours to 20 hours each week"
            ),
            Form::Option.new(
              id: "2_and_a_half_to_12_hours_per_week",
              name: "2.5 to 12 hours each week"
            ),
            Form::Option.new(
              id: "fewer_than_2_and_a_half_hours_per_week",
              name: "Fewer than 2.5 hours each week"
            )
          ]

          attribute :provider_verification_teaching_hours_per_week, :string

          validates(
            :provider_verification_teaching_hours_per_week,
            inclusion: {
              in: ->(form) do
                form.provider_verification_teaching_hours_per_week_options.map(&:id)
              end,
              message: ->(form, _) do
                "Enter how many hours they were timetabled to teach during " \
                "the #{form.claimant_term} term"
              end
            },
            unless: :save_and_exit?
          )

          def provider_verification_teaching_hours_per_week_options
            TEACHING_HOURS_PER_WEEK_OPTIONS
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
