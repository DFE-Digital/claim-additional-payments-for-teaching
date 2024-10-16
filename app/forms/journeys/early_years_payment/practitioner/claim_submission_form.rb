module Journeys
  module EarlyYearsPayment
    module Practitioner
      class ClaimSubmissionForm < ::ClaimSubmissionBaseForm
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

        def build_or_find_claim
          claim = Claim.find_by(reference: journey_session.answers.reference_number) || new_claim
          set_claim_attributes_from_answers(claim, answers)
          claim.eligibility.practitioner_claim_submitted_at = Time.zone.now
          # TODO - do we need to set a new field here?: eligibility.practitioner_claim_started_at
          claim
        end
      end
    end
  end
end
