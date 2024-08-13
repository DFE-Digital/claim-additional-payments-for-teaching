module Journeys
  module EarlyYearsPayment
    module Provider
      module Authenticated
        class CurrentNurseryForm < Form
          attribute :nursery_urn

          validates :nursery_urn,
            presence: {message: i18n_error_message(:presence)}

          attr_reader :selectable_nurseries

          def initialize(journey_session:, journey:, params:)
            super

            @selectable_nurseries = EligibleEyProvider.for_email(journey_session.answers.email_address)
          end

          def save
            return false if invalid?

            journey_session.answers.assign_attributes(nursery_urn:)
            journey_session.save!
          end
        end
      end
    end
  end
end
