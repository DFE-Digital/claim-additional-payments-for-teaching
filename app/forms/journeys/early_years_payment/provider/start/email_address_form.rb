module Journeys
  module EarlyYearsPayment
    module Provider
      module Start
        class EmailAddressForm < Form
          attribute :email_address, :string

          def save
            if Policies::EarlyYearsPayments::EligibleEyProvider.eligible_email?(email_address)
              journey_session.answers.assign_attributes(
                email_address: email_address,
                email_verified: email_verified
              )
              journey_session.save!
              ClaimMailer.early_years_payment_provider_email(answers, otp_code(email_address), email_address).deliver_now
            else
              journey_session.answers.assign_attributes(email_address: email_address)
              journey_session.save!
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

          def otp_code(email_address)
            @otp_code ||= OneTimePassword::Generator.new(secret: ROTP::Base32.encode(ENV.fetch("EY_MAGIC_LINK_SECRET") + email_address)).code
          end
        end
      end
    end
  end
end
