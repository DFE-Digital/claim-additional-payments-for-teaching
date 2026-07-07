module Journeys
  module EarlyYearsPayment
    module Provider
      module Authenticated
        class ConsentForm < Form
          attribute :consent_given, :boolean

          validates :consent_given,
            presence: {message: i18n_error_message(:presence)}

          def save
            return false if invalid?

            journey_session.answers.update!(consent_given:)
          end
        end
      end
    end
  end
end
