module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class InFirstFiveYearsForm < BaseForm
          attribute :provider_verification_in_first_five_years, :boolean

          validates(
            :provider_verification_in_first_five_years,
            included: {
              in: ->(form) { form.in_first_five_years_options.map(&:id) },
              message: "Tell us if they are in the first 5 years of their " \
                       "further education (FE) teaching career in England"
            },
            allow_nil: :save_and_exit?
          )

          def in_first_five_years_options
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
