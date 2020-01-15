class PaymentMailer < ApplicationMailer
  helper :application

  def confirmation(payment)
    @payment = payment
    @payment_date = payment.scheduled_payment_date
    @display_name = [payment.first_name, payment.surname].join(" ")

    if payment.claims.size == 1
      confirmation_for_single_claim
    else
      confirmation_for_multiple_claims
    end
  end

  private

  def confirmation_for_single_claim
    claim = @payment.claims.first
    @claim_description = I18n.t("#{claim.policy.routing_name.underscore}.claim_description")
    @reference = claim.reference
    @policy = claim.policy

    view_mail(
      NOTIFY_TEMPLATE_ID,
      to: @payment.email_address,
      subject: "We’re paying your claim #{@claim_description}, reference number: #{@reference}",
      reply_to_id: @policy.notify_reply_to_id,
      template_name: :confirmation_for_single_claim
    )
  end

  def confirmation_for_multiple_claims
    view_mail(
      NOTIFY_TEMPLATE_ID,
      to: @payment.email_address,
      subject: "We’re paying your additional payments for teaching, reference numbers: #{@payment.claims.map(&:reference).join(", ")}",
      reply_to_id: GENERIC_NOTIFY_REPLY_TO_ID,
      template_name: :confirmation_for_multiple_claims
    )
  end
end
