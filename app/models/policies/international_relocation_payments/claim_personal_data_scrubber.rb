module Policies
  module InternationalRelocationPayments
    class ClaimPersonalDataScrubber < Policies::ClaimPersonalDataScrubber
      def scrub_completed_claims
        # FIXME RL: temp NOOP until business decsion around whether TRN is
        # required in the payment claim matching has been resolved
      end
    end
  end
end
