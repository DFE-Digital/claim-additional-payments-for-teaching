module Journeys
  module EarlyYearsPayment
    module Provider
      module AlternativeIdv
        class SessionForm < ::Journeys::SessionForm
          attribute :alternative_idv_reference, :string

          def save!
            super

            if journey_session.answers.claim.present?
              journey_session.answers.send_verification_email!
            end

            true
          end
        end
      end
    end
  end
end
