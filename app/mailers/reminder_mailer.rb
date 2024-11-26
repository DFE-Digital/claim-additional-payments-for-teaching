class ReminderMailer < ApplicationMailer
  include AdditionalPaymentsHelper

  helper :application
  helper :additional_payments

  def email_verification(reminder, one_time_password, journey_name)
    @reminder = reminder
    @one_time_password = one_time_password
    @display_name = reminder.full_name
    @subject = "Please verify your reminder email"
    support_email_address = translate(:support_email_address, scope: reminder.journey::I18N_NAMESPACE)
    personalisation = {
      email_subject: @subject,
      first_name: @display_name,
      one_time_password: @one_time_password,
      support_email_address: support_email_address,
      validity_duration: one_time_password_validity_duration,
      journey_name:
    }

    send_mail(OTP_EMAIL_NOTIFY_TEMPLATE_ID, personalisation)
  end

  def reminder_set(reminder)
    @reminder = reminder
    support_email_address = translate(:support_email_address, scope: reminder.journey::I18N_NAMESPACE)

    personalisation = {
      first_name: extract_first_name(@reminder.full_name),
      support_email_address: support_email_address,
      next_application_window: @reminder.send_year
    }

    send_mail(REMINDER_SET_NOTIFY_TEMPLATE_ID, personalisation)
  end

  # TODO: This template only accommodates LUP/ECP claims currently. Needs to
  # be changed to support other policies otherwise claimants will receive the
  # wrong information. Also most of the personalisations are not used in the
  # template.
  def reminder(reminder)
    @reminder = reminder
    support_email_address = translate("additional_payments.support_email_address")

    personalisation = {
      support_email_address: support_email_address
    }

    send_mail(REMINDER_APPLICATION_WINDOW_OPEN_NOTIFY_TEMPLATE_ID, personalisation)
  end

  private

  def extract_first_name(fullname)
    (fullname || "").split(" ").first
  end

  def send_mail(template_id, personalisation)
    template_mail(
      template_id,
      to: @reminder.email_address,
      reply_to_id: GENERIC_NOTIFY_REPLY_TO_ID,
      subject: @subject,
      personalisation:
    )
  end
end
