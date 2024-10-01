module Journeys
  module EarlyYearsPayment
    module Provider
      module Authenticated
        class CheckYourAnswersForm < Form
          attribute :provider_contact_name

          validates :provider_contact_name, presence: {message: i18n_error_message(:name)}

          validate :employee_email_provided

          def save
            return false if invalid?

            journey_session.answers.assign_attributes(provider_contact_name:)
            journey_session.save!
          end

          def employee_email_provided
            if journey_session.answers.practitioner_email_address.blank?
              errors.add(:practitioner_email_address, Form.i18n_error_message(:email))
            end
          end
        end
      end
    end
  end
end
