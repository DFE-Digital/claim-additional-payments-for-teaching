class PaymentMailer < ApplicationMailer
  helper :application

  def confirmation(payment, payment_date_timestamp)
    @claim_description = I18n.t("#{payment.claim.policy.routing_name.underscore}.claim_description")
    @reference = payment.claim.reference
    @payment = payment
    @payment_date = Time.at(payment_date_timestamp).to_date
    @display_name = [payment.first_name, payment.surname].join(" ")
    @policy = payment.claim.policy

    view_mail(
      NOTIFY_TEMPLATE_ID,
      to: payment.email_address,
      subject: "We’re paying your #{@claim_description}, reference number: #{@reference}",
      reply_to_id: @policy.notify_reply_to_id
    )
  end
end
