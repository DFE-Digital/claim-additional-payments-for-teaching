class EarlyYearsPaymentsMailer < ApplicationMailer
  def submitted(claim)
    if claim.submitted_at.present?
      submitted_by_practitioner_and_send_to_practitioner(claim)
    else
      submitted_by_provider_and_send_to_provider(claim)
    end
  end

  private

  def submitted_by_provider_and_send_to_provider(claim)
    personalisation = {
      nursery_name: claim.eligibility.eligible_ey_provider.nursery_name,
      practitioner_first_name: claim.eligibility.practitioner_first_name,
      practitioner_last_name: claim.eligibility.practitioner_surname,
      ref_number: claim.reference
    }

    template_mail(
      "149c5999-12fb-4b99-aff5-23a7c3302783",
      to: claim.eligibility.eligible_ey_provider.primary_key_contact_email_address,
      subject: nil,
      reply_to_id: claim.policy.notify_reply_to_id,
      personalisation:
    )
  end

  def submitted_by_practitioner_and_send_to_practitioner(claim)
    personalisation = {
      first_name: claim.first_name,
      nursery_name: claim.eligibility.eligible_ey_provider.nursery_name,
      ref_number: claim.reference
    }

    template_mail(
      "f97480c8-7869-4af6-b50c-413929b8cc88",
      to: claim.email_address,
      subject: nil,
      reply_to_id: claim.policy.notify_reply_to_id,
      personalisation:
    )
  end
end
