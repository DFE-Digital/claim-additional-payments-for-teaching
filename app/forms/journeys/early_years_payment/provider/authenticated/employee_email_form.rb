module Journeys
  module EarlyYearsPayment
    module Provider
      module Authenticated
        class EmployeeEmailForm < Form
          attribute :practitioner_email_address

          validates :practitioner_email_address, presence: {message: i18n_error_message(:valid)}

          validates(
            :practitioner_email_address,
            email_address_format: {message: i18n_error_message(:valid)},
            if: -> { practitioner_email_address.present? }
          )

          def save
            return false if invalid?

            journey_session.answers.update!(practitioner_email_address:)
          end
        end
      end
    end
  end
end
