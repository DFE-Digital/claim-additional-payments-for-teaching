module Reminders
  class EmailVerificationForm < Form
    attribute :one_time_password, :string

    validate :validate_otp_correct

    def reminder_email_address
      journey_session.answers.reminder_email_address
    end

    def save!
      return false if invalid?

      journey_session.answers.assign_attributes(
        reminder_otp_confirmed: true
      )
      journey_session.save!

      reminder = Reminder.find_or_create_by(
        full_name: journey_session.answers.reminder_full_name,
        email_address: journey_session.answers.reminder_email_address,
        email_verified: true,
        itt_academic_year: next_academic_year.to_s,
        itt_subject:,
        journey_class: journey.to_s
      )

      ReminderMailer.reminder_set(reminder).deliver_now
    end

    def set_reminder_from_claim
    end

    private

    def itt_subject
      journey_session.answers.eligible_itt_subject
    end

    def next_academic_year
      journey.configuration.current_academic_year + 1
    end

    def validate_otp_correct
      if !validator.valid?
        errors.add(:one_time_password, validator.warning)
      end
    end

    def validator
      @validator ||= OneTimePassword::Validator.new(
        one_time_password,
        nil,
        secret: journey_session.answers.reminder_otp_secret
      )
    end
  end
end
