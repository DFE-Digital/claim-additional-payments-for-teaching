module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class TeachingHoursPerWeekForm < BaseForm
          TEACHING_HOURS_PER_WEEK_OPTIONS = [
            Form::Option.new(
              id: "20_or_more_hours_per_week",
              name: "20 hours or more per week"
            ),
            Form::Option.new(
              id: "12_to_20_hours_per_week",
              name: "12 or more hours per week, but fewer than 20"
            ),
            Form::Option.new(
              id: "2_and_a_half_to_12_hours_per_week",
              name: "2.5 or more hours per week, but fewer than 12"
            ),
            Form::Option.new(
              id: "fewer_than_2_and_a_half_hours_per_week",
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
                "Enter how many hours they were timetabled to teach during " \
                "the #{form.claimant_term} term"
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
        end
      end
    end
  end
end
