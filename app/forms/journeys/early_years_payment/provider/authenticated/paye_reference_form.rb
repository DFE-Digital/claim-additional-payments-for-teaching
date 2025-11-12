module Journeys
  module EarlyYearsPayment
    module Provider
      module Authenticated
        class PayeReferenceForm < Form
          attribute :paye_reference

          PAYE_REFERENCE_REGEX_FILTER = /\A\d{3}\/([A-Z]|\d){1,10}\z/

          validates :paye_reference, presence: {message: i18n_error_message(:valid)},
            format: {with: PAYE_REFERENCE_REGEX_FILTER, message: i18n_error_message(:valid)}

          def nursery_name
            @nursery_name ||= Policies::EarlyYearsPayments::EligibleEyProvider
              .find_by(urn: answers.nursery_urn)&.nursery_name
          end

          def save
            return false if invalid?

            journey_session.answers.assign_attributes(paye_reference:)
            journey_session.save!
          end
        end
      end
    end
  end
end
