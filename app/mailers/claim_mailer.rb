class ClaimMailer < ApplicationMailer
  include EarlyCareerPaymentsHelper
  helper :application
  helper :early_career_payments

  def submitted(claim)
    set_common_instance_variables(claim)
    @subject = "Your application #{@claim_description} has been received, reference number: #{claim.reference}"

    send_mail(:rails)
  end

  def approved(claim)
    set_common_instance_variables(claim)
    @subject = "Your application #{@claim_description} has been approved, reference number: #{claim.reference}"

    send_mail
  end

  def rejected(claim)
    set_common_instance_variables(claim)
    @subject = "Your claim #{@claim_description} has been rejected, reference number: #{claim.reference}"
    @ineligible_qts_year = @claim.policy.last_ineligible_qts_award_year

    send_mail
  end

  def update_after_three_weeks(claim)
    set_common_instance_variables(claim)
    @subject = "We are still reviewing your application #{@claim_description}, reference number: #{claim.reference}"

    send_mail
  end

  def email_verification(claim, one_time_password)
    set_common_instance_variables(claim)
    @subject = "#{@claim_subject} email verification"
    @one_time_password = one_time_password
    support_email_address = translate("#{@claim.policy.locale_key}.support_email_address")
    personalisation = {
      email_subject: @subject,
      first_name: @claim.first_name,
      one_time_password: @one_time_password,
      support_email_address: support_email_address,
      validity_duration: one_time_password_validity_duration
    }

    send_mail(:notify, OTP_EMAIL_NOTIFY_TEMPLATE_ID, personalisation)
  end

  private

  def set_common_instance_variables(claim)
    @claim = claim
    @claim_description = translate("#{@claim.policy.locale_key}.claim_description")
    @claim_subject = translate("#{@claim.policy.locale_key}.claim_subject")
    @display_name = [@claim.first_name, @claim.surname].join(" ")
    @policy = @claim.policy
  end

  def send_mail(templating = :rails, template_id = :default, personalisation = {})
    if templating == :rails
      view_mail(
        NOTIFY_TEMPLATE_ID,
        to: @claim.email_address,
        subject: @subject,
        reply_to_id: @policy.notify_reply_to_id
      )
    else
      template_mail(
        template_id,
        to: @claim.email_address,
        subject: @subject,
        reply_to_id: @policy.notify_reply_to_id,
        personalisation: personalisation
      )
    end
  end
end
