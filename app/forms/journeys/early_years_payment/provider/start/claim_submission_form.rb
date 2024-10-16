module Journeys
  module EarlyYearsPayment
    module Provider
      module Start
        class ClaimSubmissionForm < ::ClaimSubmissionBaseForm
          private

          def calculate_award_amount(eligibility)
            # NOOP
            # This is just for compatibility with the AdditionalPaymentsForTeaching
            # claim submission form.
          end

          def generate_policy_options_provided
            []
          end
        end
      end
    end
  end
end
