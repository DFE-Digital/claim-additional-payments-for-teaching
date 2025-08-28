module Journeys
  module EarlyYearsPayment
    module Provider
      module AlternativeIdv
        class SessionAnswers < Journeys::SessionAnswers
          attribute :alternative_idv_reference, :string, pii: false
          attribute :claimant_employed_by_nursery, :boolean, pii: false
          attribute :claimant_date_of_birth, :date, pii: true
          attribute :claimant_postcode, :string, pii: true
          attribute :claimant_national_insurance_number, :string, pii: true
          attribute :claimant_bank_details_match, :boolean, pii: false
          attribute :claimant_email, :string, pii: true
          attribute :claimant_employment_check_declaration, :boolean, pii: false
          attribute :alternative_idv_completed_at, :datetime, pii: false

          attribute :provider_email_verified, :boolean, pii: false
          attribute :provider_email_verification_secret, :string, pii: true
          attribute :provider_sent_one_time_password_at, :datetime, pii: false

          def claim
            @claim ||= eligibility&.claim
          end

          def nursery
            @nursery ||= eligibility.eligible_ey_provider
          end

          def alternative_idv_completed!
            assign_attributes(alternative_idv_completed_at: Time.now.utc)

            session.save!

            eligibility.update!(
              alternative_idv_claimant_employed_by_nursery: claimant_employed_by_nursery,
              alternative_idv_claimant_date_of_birth: claimant_date_of_birth,
              alternative_idv_claimant_postcode: claimant_postcode,
              alternative_idv_claimant_national_insurance_number: claimant_national_insurance_number,
              alternative_idv_claimant_bank_details_match: claimant_bank_details_match,
              alternative_idv_claimant_email: claimant_email,
              alternative_idv_claimant_employment_check_declaration: claimant_employment_check_declaration,
              alternative_idv_completed_at: alternative_idv_completed_at
            )

            Policies::EarlyYearsPayments.alternative_idv_completed!(claim)

            true
          end

          def send_verification_email!
            otp_secret = ROTP::Base32.random
            otp_code = OneTimePassword::Generator.new(secret: otp_secret).code

            assign_attributes(
              provider_email_verified: false,
              provider_email_verification_secret: otp_secret,
              provider_sent_one_time_password_at: Time.now
            )

            session.save!

            EarlyYearsPaymentsMailer.provider_alternative_idv_email_verification(
              receipient_email_address: nursery.primary_key_contact_email_address,
              one_time_password: otp_code
            ).deliver_later
          end

          private

          def eligibility
            @eligibility ||= Policies::EarlyYearsPayments::Eligibility
              .joins(:claim)
              .where(claims: {identity_confirmed_with_onelogin: false})
              .find_by(alternative_idv_reference: alternative_idv_reference)
          end
        end
      end
    end
  end
end
