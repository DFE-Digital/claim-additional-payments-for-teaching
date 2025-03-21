module Journeys
  module EarlyYearsPayment
    module Provider
      module Authenticated
        class ClaimSubmissionForm < ::ClaimSubmissionBaseForm
          def save
            super

            ClaimMailer.early_years_payment_practitioner_email(claim).deliver_later

            send_provider_completed_emails

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

          def send_provider_completed_emails
            claim.eligibility.eligible_ey_provider.email_addresses.each do |email_address|
              EarlyYearsPaymentsMailer.submitted_by_provider_and_send_to_provider(
                claim: claim,
                provider_email_address: email_address
              ).deliver_later
            end
          end
        end
      end
    end
  end
end
