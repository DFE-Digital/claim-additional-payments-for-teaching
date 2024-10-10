class PaymentMailer < ApplicationMailer
  include PaymentMailerHelper
  helper :application

  def confirmation(payment)
    @payment = payment
    @payment_date = payment.scheduled_payment_date
    @display_name = [payment.first_name, payment.surname].join(" ")

    if payment.claims.one?
      confirmation_for_single_claim
    else
      confirmation_for_multiple_claims
    end
  end

  private

  def confirmation_for_single_claim
    claim = @payment.claims.first
    claim_description = translate("#{claim.policy.locale_key}.claim_description")

    @support_email_address = translate("#{claim.policy.locale_key}.support_email_address")

    view_mail(
      NOTIFY_TEMPLATE_ID,
      to: @payment.email_address,
      subject: "We’re paying your claim #{claim_description}, reference number: #{claim.reference}",
      reply_to_id: claim.policy.notify_reply_to_id,
      template_name: :payment_breakdown_confirmation
    )
  end

  # NOTE: only happens for Additional Payments + TSLR
  def confirmation_for_multiple_claims
    @support_email_address = translate("additional_payments.support_email_address")

    view_mail(
      NOTIFY_TEMPLATE_ID,
      to: @payment.email_address,
      subject: "We’re paying your additional payments for teaching, reference numbers: #{@payment.claims.map(&:reference).join(", ")}",
      reply_to_id: GENERIC_NOTIFY_REPLY_TO_ID,
      template_name: :payment_breakdown_confirmation
    )
  end
end
