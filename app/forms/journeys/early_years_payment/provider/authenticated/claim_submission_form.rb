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
            eligibility.award_amount = Policies::EarlyYearsPayments.award_amount
          end

          def generate_policy_options_provided
            []
          end

          def set_submitted_at_attributes
            claim.eligibility.provider_claim_submitted_at = Time.zone.now
          end

          def claim_expected_to_have_email_address
            false
          end
        end
      end
    end
  end
end
