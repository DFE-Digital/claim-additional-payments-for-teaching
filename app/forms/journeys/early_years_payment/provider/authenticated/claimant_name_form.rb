module Journeys
  module EarlyYearsPayment
    module Provider
      module Authenticated
        class ClaimantNameForm < Form
          attribute :first_name
          attribute :surname
          
          NAME_REGEX_FILTER = /\A[^"=$%#&*+\/\\()@?!<>0-9]*\z/

          validates :first_name, presence: {message: i18n_error_message("first_name.presence")}
          validates :first_name,
            length: {maximum: 100, message: i18n_error_message("first_name.length")},
            format: {with: NAME_REGEX_FILTER, message: i18n_error_message("first_name.format")},
            if: -> { first_name.present? }

          validates :surname, presence: {message: i18n_error_message("last_name.presence")}
          validates :surname,
            length: {maximum: 100, message: i18n_error_message("last_name.length")},
            format: {with: NAME_REGEX_FILTER, message: i18n_error_message("last_name.format")},
            if: -> { surname.present? }

          def save
            return false if invalid?

            journey_session.answers.assign_attributes(first_name:, surname:)
            journey_session.save!
          end
        end
      end
    end
  end
end
