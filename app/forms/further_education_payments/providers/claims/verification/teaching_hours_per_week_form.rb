module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class TeachingHoursPerWeekForm < BaseForm
          TEACHING_HOURS_PER_WEEK_OPTIONS = [
            Form::Option.new(
              id: "more_than_20",
              name: "20 hours or more per week"
            ),
            Form::Option.new(
              id: "more_than_12",
              name: "12 or more hours per week, but fewer than 20"
            ),
            Form::Option.new(
              id: "between_2_5_and_12",
              name: "2.5 or more hours per week, but fewer than 12"
            ),
            Form::Option.new(
              id: "less_than_2_5",
              name: "Fewer than 2.5 hours each week"
            )
          ]

          attribute :provider_verification_teaching_hours_per_week, :string

          validates(
            :provider_verification_teaching_hours_per_week,
            included: {
              in: ->(form) do
                form.provider_verification_teaching_hours_per_week_options.map(&:id)
              end,
              message: ->(form, _) do
                "Select how many hours #{form.claimant_name} was timetabled to " \
                "teach at #{form.provider_name} during the spring term"
              end
            },
            allow_nil: :save_and_exit?
          )

          def provider_verification_teaching_hours_per_week_options
            TEACHING_HOURS_PER_WEEK_OPTIONS
          end

          def claimant_term
            claim.submitted_at.term
          end

          def school
            claim.school
          end
        end
      end
    end
  end
end
