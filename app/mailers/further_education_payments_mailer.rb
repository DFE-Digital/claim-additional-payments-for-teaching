class FurtherEducationPaymentsMailer < ApplicationMailer
  def provider_verification_overdue_chaser_email
    eligibility = params[:eligibility]

    provider_email = eligibility.school.eligible_fe_provider.primary_key_contact_email_address
    provider_name = eligibility.school.name
    claimant_name = eligibility.claim.full_name
    claim_reference = eligibility.claim.reference
    expiry_date = eligibility.verification_expiry_date

    template_mail(
      FURTHER_EDUCATION_PAYMENTS[:PROVIDER_OVERDUE_VERIFICATION_CHASER_TEMPLATE_ID],
      to: provider_email,
      reply_to_id: Policies::FurtherEducationPayments.notify_reply_to_id,
      personalisation: {
        provider_name: provider_name,
        claimant_name: claimant_name,
        claim_reference: claim_reference,
        expiry_date: expiry_date
      }
    )
  end
end
