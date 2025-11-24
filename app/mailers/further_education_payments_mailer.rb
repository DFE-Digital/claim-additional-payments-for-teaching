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
        expiry_date: expiry_date,
        link_to_provider_dashboard: further_education_payments_providers_claims_url(
          host: ENV.fetch("CANONICAL_HOSTNAME")
        )
      }
    )
  end

  def provider_weekly_update_email
    provider = params[:provider]
    provider_email = provider.primary_key_contact_email_address
    provider_name = provider.name

    claims = provider.claims.by_academic_year(
      Journeys::FurtherEducationPayments.configuration.current_academic_year
    )

    number_overdue = claims.unverified.verification_overdue.count
    number_in_progress = claims.unverified.verification_in_progress.count
    number_not_started = claims.unverified.verification_not_started.count
    number_overall = claims.unverified.count

    return if number_overall.zero?

    template_mail(
      FURTHER_EDUCATION_PAYMENTS[:PROVIDER_WEEKLY_UPDATE_TEMPLATE_ID],
      to: provider_email,
      reply_to_id: Policies::FurtherEducationPayments.notify_reply_to_id,
      personalisation: {
        provider_name: provider_name,
        number_overdue: number_overdue,
        number_in_progress: number_in_progress,
        number_not_started: number_not_started,
        number_overall: number_overall,
        link_to_provider_dashboard: further_education_payments_providers_claims_url(
          host: ENV.fetch("CANONICAL_HOSTNAME")
        )
      }
    )
  end
end
