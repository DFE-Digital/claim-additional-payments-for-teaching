module Journeys
  module EarlyYearsPayment
    module Provider
      module Authenticated
        class ClaimantNameForm < Form
          attribute :first_name
          attribute :surname

          validates :first_name, presence: {message: i18n_error_message("first_name.presence")}
          validates :first_name, length: {maximum: 100, message: i18n_error_message("first_name.length")}, if: -> { first_name.present? }
          validates :first_name, name_format: {message: i18n_error_message("first_name.format")}

          validates :surname, presence: {message: i18n_error_message("last_name.presence")}
          validates :surname, length: {maximum: 100, message: i18n_error_message("last_name.length")}, if: -> { surname.present? }
          validates :surname, name_format: {message: i18n_error_message("last_name.format")}

          def save
            return false if invalid?

            journey_session.answers.assign_attributes(
              first_name: first_name,
              surname: surname,
              practitioner_first_name: first_name,
              practitioner_surname: surname
            )
            journey_session.save!
          end
        end
      end
    end
  end
end
