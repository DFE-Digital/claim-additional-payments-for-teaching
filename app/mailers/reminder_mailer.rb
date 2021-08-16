class ReminderMailer < ApplicationMailer
  helper :application
  helper :early_career_payments

  def email_verification(reminder, one_time_password)
    @reminder = reminder
    @one_time_password = one_time_password
    @display_name = reminder.full_name
    @subject = "Please verify your reminder email"
    send_mail
  end

  def reminder_set(reminder)
    @reminder = reminder
    @subject = "Your reminder has been set"
    send_mail
  end

  def reminder(reminder, year)
    @reminder = reminder
    @year = year
    @subject = "The #{year} early-career payment window is now open"
    send_mail
  end

  private

  def send_mail
    view_mail(
      NOTIFY_TEMPLATE_ID,
      to: @reminder.email_address,
      subject: @subject
    )
  end
end
