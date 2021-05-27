class ClaimMailer < ApplicationMailer
  helper :application

  def submitted(claim)
    set_common_instance_variables(claim)
    @subject = "Your claim #{@claim_description} has been received, reference number: #{claim.reference}"

    send_mail
  end

  def approved(claim)
    set_common_instance_variables(claim)
    @subject = "Your claim #{@claim_description} has been approved, reference number: #{claim.reference}"

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
    @subject = "We are still reviewing your claim #{@claim_description}, reference number: #{claim.reference}"

    send_mail
  end

  def identity_confirmation(claim)
    set_common_instance_variables(claim)
    @subject = "We need to verify your identity #{@claim_description}, reference number: #{claim.reference}"

    send_mail
  end

  def ecp_email_verification(claim, one_time_password)
    set_common_instance_variables(claim)
    @subject = "Early-career payment email verification"
    @one_time_password = one_time_password

    send_mail
  end

  private

  def set_common_instance_variables(claim)
    @claim = claim
    @claim_description = translate("#{@claim.policy.locale_key}.claim_description")
    @display_name = [@claim.first_name, @claim.surname].join(" ")
    @policy = @claim.policy
  end

  def send_mail
    view_mail(
      NOTIFY_TEMPLATE_ID,
      to: @claim.email_address,
      subject: @subject,
      reply_to_id: @policy.notify_reply_to_id
    )
  end
end
