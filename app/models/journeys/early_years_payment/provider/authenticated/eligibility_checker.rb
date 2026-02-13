module Journeys
  module EarlyYearsPayment
    module Provider
      module Authenticated
        class EligibilityChecker < Journeys::EligibilityChecker
          def ineligibility_reason
            super || max_claims_exceeded_reason
          end

          def ineligible?
            ineligibility_reason.present?
          end

          private

          def max_claims_exceeded_reason
            return unless journey_session.answers.eligible_ey_provider
            return unless max_claims_exceeded?

            :max_claims_exceeded
          end

          def max_claims_exceeded?
            claims_in_academic_year.count >= eligible_ey_provider.max_claims
          end

          # Don't count the claim associated with the current journey session
          # otherwise we'll kick the user to ineligible when they submit the
          # final form.
          def claims_in_academic_year
            eligible_ey_provider
              .claims
              .not_rejected
              .where.not(journeys_session_id: journey_session.id)
              .where(academic_year: journey_session.answers.academic_year)
          end

          def eligible_ey_provider
            journey_session.answers.eligible_ey_provider
          end
        end
      end
    end
  end
end
