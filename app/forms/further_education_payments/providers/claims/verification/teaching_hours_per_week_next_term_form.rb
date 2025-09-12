module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class TeachingHoursPerWeekNextTermForm < BaseForm
          TEACHING_HOURS_PER_WEEK_NEXT_TERM_OPTIONS = [
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

          attribute :provider_verification_teaching_hours_per_week_next_term, :string

          validates(
            :provider_verification_teaching_hours_per_week_next_term,
            inclusion: {
              in: ->(form) do
                form.provider_verification_teaching_hours_per_week_next_term_options.map(&:id)
              end,
              message: "Enter how many hours they will be timetabled to teach next term"
            },
            unless: :save_and_exit?
          )

          def provider_verification_teaching_hours_per_week_next_term_options
            TEACHING_HOURS_PER_WEEK_NEXT_TERM_OPTIONS
          end
        end
      end
    end
  end
end
