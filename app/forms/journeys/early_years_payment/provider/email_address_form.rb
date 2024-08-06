module Journeys
  module EarlyYearsPayment
    module Provider
      class EmailAddressForm < Form
        attribute :email_address, :string

        def save
          if EligibleEyProvider.eligible_email?(email_address)
            journey_session.answers.assign_attributes(
              email_address: email_address,
              sent_one_time_password_at: Time.now,
              email_verified: email_verified
            )
            journey_session.save!

            ClaimMailer.early_years_payment_provider_email(answers, otp_code).deliver_now
          end
        end

        private

        def email_address_changed?
          email_address != answers.email_address
        end

        def email_verified
          return nil if email_address_changed?
          answers.email_verified
        end

        def otp_code
          @otp_code ||= OneTimePassword::Generator.new.code
        end
      end
    end
  end
end
