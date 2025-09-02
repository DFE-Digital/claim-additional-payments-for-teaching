module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class ClaimantEmploymentCheckNeededForm < BaseForm
          def incomplete?
            claim.eligibility.provider_verification_started_at.nil?
          end
        end
      end
    end
  end
end
