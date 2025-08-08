module Journeys
  module FurtherEducationPayments
    class WorkEmailForm < Form
      attribute :work_email, :string
      attribute :resend, :boolean

      validates :work_email,
        presence: {
          message: i18n_error_message(:presence)
        }

      def save
        return if invalid?

        if email_changed?
          journey_session.answers.assign_attributes(
            work_email_verified: false,
            work_email:,
            work_email_otp_secret: otp_secret,
            work_email_otp_timestamp: Time.zone.now
          )
          journey_session.save!

          send_email
        elsif resend
          journey_session.answers.assign_attributes(
            work_email_otp_secret: otp_secret,
            work_email_otp_timestamp: Time.zone.now
          )
          journey_session.save!

          send_email
        end

        true
      end

      def school
        journey_session.answers.school
      end

      def clear_answers_from_session
        journey_session.answers.assign_attributes(work_email: nil)
        journey_session.save!
      end

      private

      def send_email
        ClaimMailer
          .email_verification_v2(
            email: work_email,
            otp: otp_code,
            journey_name: Journeys::FurtherEducationPayments.journey_name,
            policy: Policies::FurtherEducationPayments
          ).deliver_later
      end

      def email_changed?
        journey_session.answers.work_email != work_email
      end

      def otp_secret
        @otp_secret ||= ROTP::Base32.random
      end

      def otp_code
        @otp_code ||= OneTimePassword::Generator.new(secret: otp_secret).code
      end
    end
  end
end
