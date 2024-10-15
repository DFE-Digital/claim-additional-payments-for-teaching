module Journeys
  module EarlyYearsPayment
    module Practitioner
      class ClaimSubmissionForm < ::ClaimSubmissionBaseForm
        def main_eligibility
          @main_eligibility ||= eligibilities.detect { |e| e.policy == main_policy }
        end

        def calculate_award_amount(eligibility)
          0
        end

        def main_policy
          Policies::EarlyYearsPayments
        end

        private

        def generate_policy_options_provided
          []
        end
      end
    end
  end
end
