class ClaimMailer < ApplicationMailer
  helper :application

  def submitted(claim)
    @claim_description = claim_description(claim)
    view_mail_with_claim_and_subject(claim, "Your claim #{@claim_description} has been received, reference number: #{claim.reference}")
  end

  def approved(claim)
    @claim_description = claim_description(claim)
    view_mail_with_claim_and_subject(claim, "Your claim #{@claim_description} has been approved, reference number: #{claim.reference}")
  end

  def rejected(claim)
    @claim_description = claim_description(claim)
    @possible_rejection_reasons = I18n.t("#{claim.policy.locale_key}.possible_rejection_reasons", qts_year: ineligible_qts_year(claim))
    view_mail_with_claim_and_subject(claim, "Your claim #{@claim_description} has been rejected, reference number: #{claim.reference}")
  end

  def update_after_three_weeks(claim)
    @claim_description = claim_description(claim)
    view_mail_with_claim_and_subject(claim, "We are still reviewing your claim #{@claim_description}, reference number: #{claim.reference}")
  end

  private

  def claim_description(claim)
    I18n.t("#{claim.policy.locale_key}.claim_description")
  end

  def ineligible_qts_year(claim)
    (claim.policy.first_eligible_qts_award_year - 1).to_s(:long)
  end

  def view_mail_with_claim_and_subject(claim, subject)
    @claim = claim
    @display_name = [claim.first_name, claim.surname].join(" ")
    @policy = claim.policy

    view_mail(
      NOTIFY_TEMPLATE_ID,
      to: @claim.email_address,
      subject: subject,
      reply_to_id: @policy.notify_reply_to_id
    )
  end
end
