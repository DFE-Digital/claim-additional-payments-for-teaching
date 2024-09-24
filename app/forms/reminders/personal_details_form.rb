module Reminders
  class PersonalDetailsForm < Form
    attribute :reminder_full_name, :string
    attribute :reminder_email_address, :string

    validates :reminder_full_name,
      presence: {
        message: i18n_error_message("full_name.blank")
      },
      length: {
        maximum: 100,
        message: i18n_error_message("full_name.length")
      }

    validates :reminder_email_address,
      presence: {
        message: i18n_error_message("email_address.blank")
      }

    validates :reminder_email_address,
      if: -> { reminder_email_address.present? },
      format: {
        with: Rails.application.config.email_regexp,
        message: i18n_error_message("email_address.invalid")
      },
      length: {
        maximum: 256,
        message: i18n_error_message("email_address.length")
      }

    def save!
      return false if invalid?

      journey_session.answers.assign_attributes(
        reminder_full_name:,
        reminder_email_address:,
        reminder_otp_secret:
      )

      ReminderMailer.email_verification(reminder, otp_code).deliver_now

      journey_session.save!
    end

    private

    def reminder
      @reminder ||= Reminder.new(
        journey: Journeys.for_routing_name(journey_session.journey),
        full_name: reminder_full_name,
        email_address: reminder_email_address
      )
    end

    def reminder_otp_secret
      @reminder_otp_secret ||= ROTP::Base32.random
    end

    def otp_code
      @opt_code ||= OneTimePassword::Generator.new(secret: reminder_otp_secret).code
    end
  end
end
