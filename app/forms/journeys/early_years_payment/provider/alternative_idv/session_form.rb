module Journeys
  module EarlyYearsPayment
    module Provider
      module AlternativeIdv
        class SessionForm < ::Journeys::SessionForm
          attribute :alternative_idv_reference, :string

          def save!
            super

            send_verification_email! if journey_session.answers.claim.present?

            true
          end

          private

          def send_verification_email!
            otp_secret = ROTP::Base32.random
            otp_code = OneTimePassword::Generator.new(secret: otp_secret).code

            journey_session.answers.assign_attributes(
              provider_email_verified: false,
              provider_email_verification_secret: otp_secret,
              provider_sent_one_time_password_at: Time.now
            )

            journey_session.save!

            nursery = journey_session.answers.nursery

            EarlyYearsPaymentsMailer.provider_alternative_idv_email_verification(
              receipient_email_address: nursery.primary_key_contact_email_address,
              one_time_password: otp_code
            ).deliver_later
          end
        end
      end
    end
  end
end
