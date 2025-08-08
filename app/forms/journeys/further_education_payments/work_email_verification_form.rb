module Journeys
  module FurtherEducationPayments
    class WorkEmailVerificationForm < Form
      attribute :work_email_otp, :string

      validates :work_email_otp,
        presence: {
          message: i18n_error_message(:presence)
        }

      validate :otp_must_be_valid

      def save
        return if invalid?

        journey_session.answers.assign_attributes(work_email_verified: true)
        journey_session.save!
      end

      def completed?
        journey_session.answers.work_email_verified?
      end

      def school
        journey_session.answers.school
      end

      def work_email
        journey_session.answers.work_email
      end

      private

      def otp_must_be_valid
        otp = OneTimePassword::Validator.new(
          work_email_otp,
          journey_session.answers.work_email_otp_timestamp,
          secret: journey_session.answers.work_email_otp_secret
        )

        errors.add(:work_email_otp, otp.warning) unless otp.valid?
      end
    end
  end
end
