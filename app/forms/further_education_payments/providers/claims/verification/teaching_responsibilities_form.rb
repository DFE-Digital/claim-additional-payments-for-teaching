module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class TeachingResponsibilitiesForm < BaseForm
          attribute :provider_verification_teaching_responsibilities, :boolean

          validates(
            :provider_verification_teaching_responsibilities,
            inclusion: {
              in: ->(form) { form.teaching_responsibilities_options.map(&:id) },
              message: "Tell us if they are a member of staff with teaching " \
                       "responsibilities"
            },
            unless: :save_and_exit?
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
