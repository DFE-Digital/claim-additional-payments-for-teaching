module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class TeachingResponsibilitiesForm < BaseForm
          attribute :provider_verification_teaching_responsibilities, :boolean

          validates(
            :provider_verification_teaching_responsibilities,
            included: {
              in: ->(form) { form.teaching_responsibilities_options.map(&:id) }
            },
            allow_nil: :save_and_exit?
          )

          def teaching_responsibilities_options
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
