module Journeys
  module EarlyYearsPayment
    module Provider
      module AlternativeIdv
        class EligibilityChecker
          attr_reader :journey_session

          def initialize(journey_session:)
            @journey_session = journey_session
          end

          def ineligible?
            ineligibility_reason.present?
          end

          def ineligibility_reason
            if journey_session.answers.claim.nil?
              :claim_not_found
            elsif alternative_idv_already_completed?
              :alternative_idv_already_completed
            end
          end

          private

          def alternative_idv_already_completed?
            eligibility.alternative_idv_completed? &&
              !alternative_idv_completed_this_session?
          end

          def eligibility
            @eligibility ||= journey_session.answers.claim.eligibility
          end

          # If the provider is viewing one of the post completion pages we don't
          # want the eligiblity checker to kick them out of the journey
          def alternative_idv_completed_this_session?
            # Convert to string to avoid precision issues
            unless journey_session.answers.alternative_idv_completed_at.present?
              return false
            end

            eligibility.alternative_idv_completed_at.utc.to_s ==
              journey_session.answers.alternative_idv_completed_at.utc.to_s
          end
        end
      end
    end
  end
end
