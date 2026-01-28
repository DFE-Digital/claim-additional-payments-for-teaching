module Journeys
  module EarlyYearsTeachers
    module Provider
      class ProviderEmailForm < Form
        attribute :provider_email_address, :string

        validates(
          :provider_email_address,
          presence: {message: i18n_error_message(:invalid)}
        )

        validates(
          :provider_email_address,
          email_address_format: {message: i18n_error_message(:invalid)},
          if: -> { provider_email_address.present? }
        )

        def save
          return false if invalid?

          journey_session.answers.assign_attributes(
            provider_email_address: provider_email_address
          )
          journey_session.save!
        end
      end
    end
  end
end
