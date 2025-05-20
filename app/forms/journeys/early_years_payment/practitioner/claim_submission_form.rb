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

        def existing_or_new_claim
          Claim.find_by(reference: journey_session.answers.reference_number) || Claim.new
        end

        def build_claim
          existing_or_new_claim.tap do |claim|
            claim.eligibility ||= main_eligibility
            claim.policy ||= main_eligibility.policy
            claim.eligibility.practitioner_claim_started_at = journey_session.answers.practitioner_claim_started_at
            answers.attributes.each do |name, value|
              if claim.respond_to?(:"#{name}=")
                claim.public_send(:"#{name}=", value)
              end
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
