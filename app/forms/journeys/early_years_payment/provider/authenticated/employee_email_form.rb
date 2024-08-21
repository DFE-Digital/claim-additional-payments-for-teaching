module Journeys
  module EarlyYearsPayment
    module Provider
      module Authenticated
        class EmployeeEmailForm < Form
          attribute :practitioner_email_address

          validates :practitioner_email_address, presence: {message: i18n_error_message(:valid)}

          def save
            return false if invalid?

            journey_session.answers.assign_attributes(practitioner_email_address:)
            journey_session.save!
          end
        end
      end
    end
  end
end
