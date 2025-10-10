module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class InFirstFiveYearsForm < BaseForm
          attribute :provider_verification_teaching_start_year_matches_claim, :boolean

          validates(
            :provider_verification_teaching_start_year_matches_claim,
            included: {
              in: ->(form) { form.teaching_start_year_matches_claim_options.map(&:id) },
              message: ->(form, _) do
                "Select yes if #{form.claimant_name} started their FE teaching career " \
                "in England during #{form.claimant_further_education_teaching_start_year}"
              end
            },
            allow_nil: :save_and_exit?
          )

          def teaching_start_year_matches_claim_options
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
