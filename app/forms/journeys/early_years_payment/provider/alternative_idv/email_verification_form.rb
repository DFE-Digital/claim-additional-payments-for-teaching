module Journeys
  module EarlyYearsPayment
    module Provider
      module AlternativeIdv
        class EmailVerificationForm < Form
          attribute :one_time_password, :string

          validate :one_time_password_is_valid

          before_validation do
            self.one_time_password = (one_time_password || "").gsub(/\D/, "")
          end

          def completed?
            journey_session.reload.answers.provider_email_verified?
          end

          def email_address
            answers.nursery.primary_key_contact_email_address
          end

          def save
            return false unless valid?

            journey_session.answers.assign_attributes(
              provider_email_verified: true
            )

            journey_session.save!

            true
          end

          def back_link_path
            AlternativeIdv.verification_path(answers.claim)
          end

          private

          def one_time_password_is_valid
            otp = OneTimePassword::Validator.new(
              one_time_password,
              answers.provider_sent_one_time_password_at,
              secret: answers.provider_email_verification_secret
            )

            errors.add(:one_time_password, otp.warning) unless otp.valid?
          end
        end
      end
    end
  end
end
