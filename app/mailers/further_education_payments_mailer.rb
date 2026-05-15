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

    stats = FurtherEducationPayments::Providers::Claims::Stats.new(provider: provider)

    number_overall = stats.unverified_overall_count

    return if number_overall.zero?

    template_mail(
      FURTHER_EDUCATION_PAYMENTS[:PROVIDER_WEEKLY_UPDATE_TEMPLATE_ID],
      to: provider_email,
      reply_to_id: Policies::FurtherEducationPayments.notify_reply_to_id,
      personalisation: {
        provider_name: provider_name,
        number_overdue: stats.unverified_overdue_count,
        number_in_progress: stats.unverified_in_progress_count,
        number_not_started: stats.unverified_not_started_count,
        number_overall: number_overall,
        link_to_provider_dashboard: further_education_payments_providers_claims_url(
          host: ENV.fetch("CANONICAL_HOSTNAME")
        )
      }
    )
  end
end
