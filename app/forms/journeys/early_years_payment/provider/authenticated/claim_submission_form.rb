module Journeys
  module EarlyYearsPayment
    module Provider
      module Authenticated
        class ClaimSubmissionForm < ::ClaimSubmissionBaseForm
          def save
            super

            ClaimMailer.early_years_payment_practitioner_email(claim).deliver_later

            true
          end

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
