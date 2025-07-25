module FurtherEducationPayments
  module Providers
    module Claims
      class ClaimPresenter
        include Policies::FurtherEducationPayments::ProviderVerificationConstants

        attr_reader :claim

        def initialize(claim)
          @claim = claim
        end

        def status
          case provider_verification_status
          when STATUS_NOT_STARTED
            "Not started"
          when STATUS_IN_PROGRESS
            "In progress"
          when STATUS_COMPLETED
            "Completed"
          else
            "Unknown"
          end
        end

        def colour
          case provider_verification_status
          when STATUS_NOT_STARTED
            "red"
          when STATUS_IN_PROGRESS
            "yellow"
          when STATUS_COMPLETED
            "green"
          else
            "grey"
          end
        end

        def processed_by
          claim.eligibility.processed_by_label
        end

        private

        def provider_verification_status
          claim.eligibility.provider_verification_status
        end
      end
    end
  end
end
