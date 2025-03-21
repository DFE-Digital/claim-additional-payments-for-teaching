class EarlyYearsPaymentsMailer < ApplicationMailer
  def submitted(claim)
    if claim.submitted_at.present?
      submitted_by_practitioner_and_send_to_practitioner(claim)
    end
  end

  def progress_update
    claim = params[:claim]

    personalisation = {
      first_name: claim.first_name,
      application_date: claim.submitted_at.to_date.to_fs(:long_date),
      ref_number: claim.reference
    }

    template_mail(
      "1d20d638-61e4-4768-beba-c447cfa8c5a7",
      to: claim.email_address,
      subject: nil,
      reply_to_id: claim.policy.notify_reply_to_id,
      personalisation:
    )
  end

  def approved(claim)
    self.class.practitioner_approved(claim).deliver_later
    self.class.provider_approved(claim).deliver_later
  end

  def practitioner_approved(claim)
    personalisation = {
      ref_number: claim.reference,
      first_name: claim.first_name
    }

    template_mail(
      "13b60fab-8306-4cb4-84e1-8a0ff905aba6",
      to: claim.email_address,
      subject: nil,
      reply_to_id: claim.policy.notify_reply_to_id,
      personalisation:
    )
  end

  def provider_approved(claim)
    personalisation = {
      ref_number: claim.reference,
      first_name: claim.provider_contact_name,
      practitioner_first_name: claim.first_name,
      practitioner_last_name: claim.surname
    }

    template_mail(
      "aa714fac-3fd7-4d3c-a510-2445c16be446",
      to: claim.eligibility.eligible_ey_provider.primary_key_contact_email_address,
      subject: nil,
      reply_to_id: claim.policy.notify_reply_to_id,
      personalisation:
    )
  end

  def submitted_by_provider_and_send_to_provider(claim:, provider_email_address:)
    personalisation = {
      nursery_name: claim.eligibility.eligible_ey_provider.nursery_name,
      practitioner_first_name: claim.eligibility.practitioner_first_name,
      practitioner_last_name: claim.eligibility.practitioner_surname,
      ref_number: claim.reference
    }

    template_mail(
      "149c5999-12fb-4b99-aff5-23a7c3302783",
      to: provider_email_address,
      subject: nil,
      reply_to_id: claim.policy.notify_reply_to_id,
      personalisation:
    )
  end

  private

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
