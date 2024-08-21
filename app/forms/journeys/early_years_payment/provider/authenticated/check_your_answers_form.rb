module Journeys
  module EarlyYearsPayment
    module Provider
      module Authenticated
        class CheckYourAnswersForm < Form
          attribute :provider_contact_name

          validates :provider_contact_name, presence: {message: i18n_error_message(:valid)}

          def save
            return false if invalid?

            journey_session.answers.assign_attributes(provider_contact_name:)
            journey_session.save!
          end
        end
      end
    end
  end
end
