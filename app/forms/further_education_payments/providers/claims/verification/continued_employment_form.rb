module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class ContinuedEmploymentForm < BaseForm
          attribute :provider_verification_continued_employment, :boolean

          validates(
            :provider_verification_continued_employment,
            included: {
              in: ->(form) { form.continued_employment_options.map(&:id) },
              message: ->(form, _) do
                "Select yes if #{form.claimant_name} is expected to work " \
                "at #{form.provider_name} or another eligible FE provider until the end of the academic year"
              end
            },
            allow_nil: :save_and_exit?
          )

          def continued_employment_options
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
