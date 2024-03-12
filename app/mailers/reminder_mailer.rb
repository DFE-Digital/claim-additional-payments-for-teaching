class ReminderMailer < ApplicationMailer
  include AdditionalPaymentsHelper

  helper :application
  helper :additional_payments

  def email_verification(reminder, one_time_password)
    @reminder = reminder
    @one_time_password = one_time_password
    @display_name = reminder.full_name
    @subject = "Please verify your reminder email"
    support_email_address = translate("additional_payments.support_email_address")
    personalisation = {
      email_subject: @subject,
      first_name: @display_name,
      one_time_password: @one_time_password,
      support_email_address: support_email_address,
      validity_duration: one_time_password_validity_duration
    }

    send_mail(OTP_EMAIL_NOTIFY_TEMPLATE_ID, personalisation)
  end

  def reminder_set(reminder)
    @reminder = reminder
    support_email_address = translate("additional_payments.support_email_address")

    personalisation = {
      first_name: extract_first_name(@reminder.full_name),
      support_email_address: support_email_address,
      next_application_window: @reminder.send_year
    }

    send_mail(REMINDER_SET_NOTIFY_TEMPLATE_ID, personalisation)
  end

  def reminder(reminder)
    @reminder = reminder
    support_email_address = translate("additional_payments.support_email_address")
    service_start_page_url = Journeys::Configuration.start_page_url("additional-payments")
    personalisation = {
      first_name: extract_first_name(@reminder.full_name),
      support_email_address: support_email_address,
      itt_academic_year: @reminder.itt_academic_year,
      service_start_page_url: service_start_page_url
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
      reply_to_id: Policies::EarlyCareerPayments.notify_reply_to_id,
      subject: @subject,
      personalisation:
    )
  end
end
