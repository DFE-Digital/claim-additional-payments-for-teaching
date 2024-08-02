module Journeys
  module EarlyYearsPayment
    module Provider
      class EmailAddressForm < Form
        attribute :email_address, :string

        def save
          journey_session.answers.assign_attributes(
            email_address: email_address
          )
          journey_session.save!

          ClaimMailer.early_years_payment_provider_email(answers, otp_code).deliver_now
        end

        private

        def otp_code
          @otp_code ||= OneTimePassword::Generator.new.code
        end
      end
    end
  end
end
