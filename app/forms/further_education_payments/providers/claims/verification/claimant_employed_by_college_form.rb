module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class ClaimantEmployedByCollegeForm < BaseForm
          attribute :provider_verification_claimant_employed_by_college, :boolean

          validates(
            :provider_verification_claimant_employed_by_college,
            inclusion: {
              in: ->(form) { form.claimant_employed_by_college.map(&:id) },
              message: ->(form, _) do
                "Select yes if #{form.provider_name} employs #{form.claimant_name}"
              end
            }
          )

          def claimant_employed_by_college
            [
              Form::Option.new(id: true, name: "Yes"),
              Form::Option.new(id: false, name: "No")
            ]
          end

          private

          # If the provider has indicated that the claimant is not employed by
          # the college we want to mark the verification as complete, in such
          # cases this form will be the last one in the verification flow.
          def attributes_to_save
            if not_employed_by_college?
              super + %w[
                provider_verification_completed_at
                provider_verification_verified_by_id
              ]
            else
              super
            end
          end

          def not_employed_by_college?
            provider_verification_claimant_employed_by_college == false
          end

          def provider_verification_completed_at
            DateTime.current
          end

          def provider_verification_verified_by_id
            user.id
          end
        end
      end
    end
  end
end
