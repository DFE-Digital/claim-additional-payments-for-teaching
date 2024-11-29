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

      ReminderMailer.email_verification(reminder, otp_code, journey_session.journey_class.journey_name).deliver_now

      journey_session.save!
    end

    def set_reminder_from_claim
      if submitted_claim.present? && submitted_claim.email_verified?
        reminder = Reminder.find_or_create_by(
          full_name: submitted_claim.full_name,
          email_address: submitted_claim.email_address,
          email_verified: true,
          itt_subject: itt_subject_for_submitted_claim,
          itt_academic_year: next_academic_year.to_s,
          journey_class: journey.to_s
        )

        ReminderMailer.reminder_set(reminder).deliver_now
      else
        false
      end
    end

    private

    def submitted_claim
      Claim.find_by(id: session["submitted_claim_id"])
    end

    def itt_subject_for_submitted_claim
      submitted_claim.eligible_itt_subject
    end

    def next_academic_year
      journey.configuration.current_academic_year + 1
    end

    def reminder
      @reminder ||= Reminder.new(
        full_name: reminder_full_name,
        email_address: reminder_email_address,
        journey_class: journey.to_s
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
