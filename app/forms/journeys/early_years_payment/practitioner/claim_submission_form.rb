module Journeys
  module EarlyYearsPayment
    module Practitioner
      class ClaimSubmissionForm < ::ClaimSubmissionBaseForm
        def main_eligibility
          @main_eligibility ||= eligibilities.detect { |e| e.policy == main_policy }
        end

        def calculate_award_amount(claim)
          claim.award_amount = 0
        end

        def main_policy
          Policies::EarlyYearsPayments
        end
      end
    end
  end
end
