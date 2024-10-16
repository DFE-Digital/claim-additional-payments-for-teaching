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
          # TODO - set a new field: eligibility.practitioner_claim_started_at?
          set_claim_attributes_from_answers(claim, answers)

          claim
        end
      end
    end
  end
end
