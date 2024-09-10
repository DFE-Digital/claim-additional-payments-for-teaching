module Reminders
  class EmailVerificationForm < Form
    attribute :one_time_password, :string

    validate :validate_otp_correct

    def save!
      return false if invalid?

      journey_session.answers.assign_attributes(
        reminder_otp_confirmed: true
      )
      journey_session.save!
      reminder = Reminder.find_or_create_by(
        journey: Journeys.for_routing_name(journey_session.journey).to_s,
        full_name: journey_session.answers.reminder_full_name,
        email_address: journey_session.answers.reminder_email_address,
        email_verified: true,
        itt_academic_year: next_academic_year.to_s
      )

      ReminderMailer.reminder_set(reminder).deliver_now
    end

    private

    def next_academic_year
      AcademicYear.next
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
