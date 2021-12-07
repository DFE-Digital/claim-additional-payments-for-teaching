class ReminderMailer < ApplicationMailer
  helper :application
  helper :early_career_payments

  def email_verification(reminder, one_time_password)
    @reminder = reminder
    @one_time_password = one_time_password
    @display_name = reminder.full_name
    @subject = "Please verify your reminder email"
    personalisation = {
      first_name: @display_name,
      one_time_password: @one_time_password
    }

    send_mail(:notify, OTP_EMAIL_NOTIFY_TEMPLATE_ID, personalisation)
  end

  def reminder_set(reminder)
    @reminder = reminder
    @subject = "Your reminder has been set"
    send_mail
  end

  def reminder(reminder)
    @reminder = reminder
    @subject = "The #{reminder.itt_academic_year} early-career payment window is now open"
    send_mail
  end

  private

  def send_mail(templating = :rails, template_id = :default, personalisation = {})
    if templating == :rails
      view_mail(
        NOTIFY_TEMPLATE_ID,
        to: @reminder.email_address,
        subject: @subject
      )
    else
      puts "Using GOVUK Notify templating - template_id: #{template_id}"
      template_mail(
        template_id,
        to: @reminder.email_address,
        subject: @subject,
        personalisation: personalisation
      )
    end
  end
end
