module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class ContinueVerificationForm < BaseForm
          attribute :continue_verification, :boolean

          validates(
            :continue_verification,
            included: {
              in: ->(form) { form.continue_verification_options.map(&:id) },
              message: "Tell us if you want to continue verifying this claim"
            }
          )

          def continue_verification_options
            [
              Form::Option.new(id: true, name: "Yes"),
              Form::Option.new(id: false, name: "No, I just want to see the claim")
            ]
          end

          def save
            return true if read_only?

            super
          end

          def incomplete?
            claim.eligibility.provider_assigned_to_id.present? &&
              claim.eligibility.provider_assigned_to_id != provider_assigned_to_id
          end

          def read_only?
            continue_verification == false
          end

          def started_by
            DfeSignIn::User
              .find_by(id: claim.eligibility.provider_assigned_to_id)&.full_name
          end

          private

          def attributes_to_save
            %w[provider_assigned_to_id]
          end

          def provider_assigned_to_id
            user.id
          end
        end
      end
    end
  end
end
