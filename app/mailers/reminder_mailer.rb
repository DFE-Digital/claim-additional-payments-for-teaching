class ReminderMailer < ApplicationMailer
  helper :application
  helper :early_career_payments

  def email_verification(reminder, one_time_password)
    @one_time_password = one_time_password
    @display_name = reminder.full_name

    view_mail(
      NOTIFY_TEMPLATE_ID,
      to: reminder.email_address,
      subject: "Reminder email verification"
    )
  end
end
