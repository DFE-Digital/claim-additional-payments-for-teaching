module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class TimetabledTeachingHoursForm < BaseForm
          attribute :provider_verification_timetabled_teaching_hours, :boolean

          validates(
            :provider_verification_timetabled_teaching_hours,
            inclusion: {
              in: ->(form) do
                form.provider_verification_timetabled_teaching_hours_options.map(&:id)
              end,
              message: ->(form, _) do
                "Tell us if they are timetabled to teach at least 2.5 hours " \
                "per week in the #{form.term} term"
              end
            },
            unless: :save_and_exit?
          )

          def provider_verification_timetabled_teaching_hours_options
            [
              Form::Option.new(id: true, name: "Yes"),
              Form::Option.new(id: false, name: "No")
            ]
          end

          def term
            # FIXME - placeholder until CAPT-2711 is implemented
            "[spring_or_summer]"
          end
        end
      end
    end
  end
end
