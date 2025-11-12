module Journeys
  module EarlyYearsPayment
    module Provider
      module Authenticated
        class CurrentNurseryForm < Form
          attribute :nursery_urn

          validates :nursery_urn,
            presence: {message: i18n_error_message(:presence)}

          validate :nursery_is_valid_for_user

          attr_reader :selectable_nurseries

          def initialize(journey_session:, journey:, params:, session: {})
            super

            @selectable_nurseries = Policies::EarlyYearsPayments::EligibleEyProvider
              .for_email(journey_session.answers.provider_email_address)
          end

          def save
            return false if invalid?

            journey_session.answers.assign_attributes(nursery_urn:)
            journey_session.save!
          end

          def nursery_is_valid_for_user
            return if nursery_urn.blank? || nursery_urn == "none_of_the_above"

            unless Policies::EarlyYearsPayments::EligibleEyProvider
                .for_email(journey_session.answers.provider_email_address)
                .pluck(:urn)
                .include?(nursery_urn)

              errors.add(:nursery_urn, "is not associated with your email address")
            end
          end
        end
      end
    end
  end
end
