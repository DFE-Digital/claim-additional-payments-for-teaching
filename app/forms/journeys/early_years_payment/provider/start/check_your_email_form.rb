module Journeys
  module EarlyYearsPayment
    module Provider
      module Start
        class CheckYourEmailForm < Form
          attribute :resend, :boolean

          def completed?
            false
          end

          def save
            ClaimMailer.early_years_payment_provider_email(answers, otp_code(answers.email_address), answers.email_address).deliver_now

            false
          end

          private

          def otp_code(email_address)
            @otp_code ||= OneTimePassword::Generator.new(secret: ROTP::Base32.encode(ENV.fetch("EY_MAGIC_LINK_SECRET") + email_address)).code
          end
        end
      end
    end
  end
end
