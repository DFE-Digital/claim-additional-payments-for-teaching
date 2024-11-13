module Policies
  module EarlyYearsPayments
    class ClaimPersonalDataScrubber < Policies::ClaimPersonalDataScrubber
      def old_rejected_claims
        claims_rejected_before(1.year.ago)
      end

      def old_paid_claims
        claims_paid_before(1.year.ago)
      end
    end
  end
end
