module Journeys
  module EarlyYearsPayment
    module Practitioner
      class ClaimSubmissionForm < ::ClaimSubmissionBaseForm
        def calculate_award_amount(eligibility)
          # NOOP
          # This is just for compatibility with the AdditionalPaymentsForTeaching
          # claim submission form.
        end

        def main_policy
          Policies::EarlyYearsPayments
        end

        private

        def generate_policy_options_provided
          []
        end

        def new_or_find_claim
          (Claim.find_by(reference: journey_session.answers.reference_number) || Claim.new).tap do |c|
            if c.eligibility
              c.eligibility.practitioner_claim_started_at = journey_session.answers.practitioner_claim_started_at
            end
          end
        end

        def set_submitted_at_attributes
          claim.submitted_at = Time.zone.now
        end
      end
    end
  end
end
