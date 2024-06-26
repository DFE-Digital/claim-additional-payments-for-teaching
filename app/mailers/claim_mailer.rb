class ClaimMailer < ApplicationMailer
  include ClaimMailerHelper
  include AdditionalPaymentsHelper
  helper :application

  def submitted(claim)
    unknown_policy_check(claim)
    set_common_instance_variables(claim)
    personalisation = {
      first_name: @claim.first_name,
      ref_number: @claim.reference,
      support_email_address: @support_email_address
    }

    send_mail(template_ids(claim)[:CLAIM_RECEIVED_NOTIFY_TEMPLATE_ID], personalisation)
  end

  def approved(claim)
    unknown_policy_check(claim)
    set_common_instance_variables(claim)
    personalisation = {
      first_name: @claim.first_name,
      ref_number: @claim.reference,
      support_email_address: @support_email_address
    }

    send_mail(template_ids(claim)[:CLAIM_APPROVED_NOTIFY_TEMPLATE_ID], personalisation)
  end

  def rejected(claim)
    unknown_policy_check(claim)
    set_common_instance_variables(claim)
    personalisation = {
      first_name: @claim.first_name,
      ref_number: @claim.reference,
      support_email_address: @support_email_address,
      current_financial_year: (claim.policy == Policies::StudentLoans) ? Policies::StudentLoans.current_financial_year : "",
      **rejected_reasons_personalisation(@claim.latest_decision&.rejected_reasons_hash)
    }

    send_mail(template_ids(claim)[:CLAIM_REJECTED_NOTIFY_TEMPLATE_ID], personalisation)
  end

  def update_after_three_weeks(claim)
    unknown_policy_check(claim)
    set_common_instance_variables(claim)

    personalisation = {
      first_name: @claim.first_name,
      ref_number: @claim.reference,
      support_email_address: @support_email_address,
      application_date: l(@claim.submitted_at.to_date)
    }

    send_mail(template_ids(claim)[:CLAIM_UPDATE_AFTER_THREE_WEEKS_NOTIFY_TEMPLATE_ID], personalisation)
  end

  def email_verification(claim, one_time_password)
    unknown_policy_check(claim)
    set_common_instance_variables(claim)
    @subject = "#{@claim_subject} email verification"
    @one_time_password = one_time_password
    personalisation = {
      email_subject: @subject,
      first_name: @claim.first_name,
      one_time_password: @one_time_password,
      support_email_address: @support_email_address,
      validity_duration: one_time_password_validity_duration
    }

    send_mail(OTP_EMAIL_NOTIFY_TEMPLATE_ID, personalisation)
  end

  private

  def set_common_instance_variables(claim)
    @claim = claim
    @claim_description = translate("#{@claim.policy.locale_key}.claim_description")
    @claim_subject = translate("#{@claim.policy.locale_key}.claim_subject")
    @display_name = [@claim.first_name, @claim.surname].join(" ")
    @policy = @claim.policy
    @support_email_address = translate("#{@claim.policy.locale_key}.support_email_address")
  end

  def template_ids(claim)
    "ApplicationMailer::#{claim.policy.to_s.underscore.upcase}".safe_constantize
  end

  def send_mail(template_id, personalisation)
    template_mail(
      template_id,
      to: @claim.email_address,
      subject: @subject,
      reply_to_id: @policy.notify_reply_to_id,
      personalisation:
    )
  end

  def unknown_policy_check(claim)
    return if [
      Policies::StudentLoans,
      Policies::EarlyCareerPayments,
      Policies::LevellingUpPremiumPayments,
      Policies::InternationalRelocationPayments
    ].include?(claim.policy)
    raise ArgumentError, "Unknown claim policy: #{claim.policy}"
  end
end
