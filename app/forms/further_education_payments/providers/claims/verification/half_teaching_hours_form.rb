module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class HalfTeachingHoursForm < BaseForm
          attribute :provider_verification_half_teaching_hours, :boolean

          validates(
            :provider_verification_half_teaching_hours,
            included: {
              in: ->(form) do
                form.provider_verification_half_teaching_hours_options.map(&:id)
              end
            },
            allow_nil: :save_and_exit?
          )

          def provider_verification_half_teaching_hours_options
            [
              Form::Option.new(id: true, name: "Yes"),
              Form::Option.new(id: false, name: "No")
            ]
          end
        end
      end
    end
  end
end
