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

    claim.eligibility.eligible_ey_provider.email_addresses.each do |email_address|
      self.class.provider_approved(
        claim: claim,
        provider_email_address: email_address
      ).deliver_later
    end
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

  def submitted_by_provider_and_send_to_provider(claim:, provider_email_address:)
    personalisation = {
      nursery_name: claim.eligibility.eligible_ey_provider.nursery_name,
      practitioner_first_name: claim.eligibility.practitioner_first_name,
      practitioner_last_name: claim.eligibility.practitioner_surname,
      provider_contact_name: claim.provider_contact_name,
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

  def provider_approved(claim:, provider_email_address:)
    personalisation = {
      ref_number: claim.reference,
      first_name: claim.provider_contact_name,
      practitioner_first_name: claim.first_name,
      practitioner_last_name: claim.surname
    }

    template_mail(
      "aa714fac-3fd7-4d3c-a510-2445c16be446",
      to: provider_email_address,
      subject: nil,
      reply_to_id: claim.policy.notify_reply_to_id,
      personalisation:
    )
  end

  def provider_alternative_idv_request(claim)
    personalisation = {
      claim_reference: claim.reference,
      provider_name: claim.provider_contact_name,
      practitioner_first_name: claim.first_name,
      practitioner_full_name: claim.full_name,
      verification_url: Journeys::EarlyYearsPayment::Provider::AlternativeIdv.verification_url(claim)
    }

    template_mail(
      EARLY_YEARS_PAYMENTS[:CLAIM_ALTERNATIVE_IDV_NOTIFY_TEMPLATE_ID],
      to: claim.eligibility.eligible_ey_provider.primary_key_contact_email_address,
      reply_to_id: claim.policy.notify_reply_to_id,
      personalisation: personalisation
    )
  end

  def provider_alternative_idv_email_verification(receipient_email_address:, one_time_password:)
    template_mail(
      EARLY_YEARS_PAYMENTS[:CLAIM_ALTERNATIVE_IDV_EMAIL_VERIFICATION_TEMPLATE_ID],
      to: receipient_email_address,
      reply_to_id: Policies::EarlyYearsPayments.notify_reply_to_id,
      personalisation: {
        one_time_password: one_time_password
      }
    )
  end

  def provider_six_month_employment_reminder
    claim = params[:claim]

    template_mail(
      EARLY_YEARS_PAYMENTS[:PROVIDER_SIX_MONTH_EMPLOYMENT_REMINDER_TEMPLATE_ID],
      to: claim.eligibility.eligible_ey_provider.primary_key_contact_email_address,
      reply_to_id: claim.policy.notify_reply_to_id,
      personalisation: {
        ref_number: claim.reference,
        provider_contact_name: claim.provider_contact_name,
        practitioner_first_name: claim.first_name,
        practitioner_last_name: claim.surname,
        provider_submission_date: I18n.l(claim.eligibility.provider_claim_submitted_at.to_date),
        nursery_name: claim.eligibility.eligible_ey_provider.nursery_name
      }
    )
  end

  def practitioner_claim_reminder
    claim = params[:claim]

    complete_claim_url = "https://#{ENV["CANONICAL_HOSTNAME"]}/#{Journeys::EarlyYearsPayment::Practitioner::ROUTING_NAME}/landing-page"

    template_mail(
      EARLY_YEARS_PAYMENTS[:PRACTITIONER_CLAIM_REMINDER_TEMPLATE_ID],
      to: claim.practitioner_email_address,
      reply_to_id: claim.policy.notify_reply_to_id,
      personalisation: {
        practitioner_first_name: claim.first_name,
        practitioner_second_name: claim.surname,
        nursery_name: claim.eligibility.eligible_ey_provider.nursery_name,
        complete_claim_url: complete_claim_url,
        ref_number: claim.reference
      }
    )
  end

  private

  def submitted_by_practitioner_and_send_to_practitioner(claim)
    complete_claim_url = "https://#{ENV["CANONICAL_HOSTNAME"]}/#{Journeys::EarlyYearsPayment::Practitioner::ROUTING_NAME}/claims?claim_id=#{claim.id}"

    personalisation = {
      first_name: claim.first_name,
      nursery_name: claim.eligibility.eligible_ey_provider.nursery_name,
      ref_number: claim.reference,
      complete_claim_url: complete_claim_url
    }

    template_mail(
      "f97480c8-7869-4af6-b50c-413929b8cc88",
      to: claim.email_address,
      subject: nil,
      reply_to_id: claim.policy.notify_reply_to_id,
      personalisation:
    )
  end

  def template_mail(template_id, options)
    if Rails.env.development?
      puts
      puts "Template ID: #{template_id}"
      puts "To: #{options[:to]}"
      puts "Personalisation: #{options[:personalisation]}"
      puts
    end

    super
  end
end
