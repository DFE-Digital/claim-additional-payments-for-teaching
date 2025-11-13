class FurtherEducationPaymentsMailer < ApplicationMailer
  def provider_weekly_update
    provider = params[:provider]
    claims = params[:claims]

    not_started_claims = claims.select { |claim| claim.eligibility.provider_verification_status == Policies::FurtherEducationPayments::ProviderVerificationConstants::STATUS_NOT_STARTED }
    in_progress_claims = claims.select { |claim| claim.eligibility.provider_verification_status == Policies::FurtherEducationPayments::ProviderVerificationConstants::STATUS_IN_PROGRESS }
    overdue_claims = claims.select { |claim| Policies::FurtherEducationPayments.verification_overdue?(claim) }

    personalisation = {
      "provider_name" => provider.organisation_name,
      "number_overdue" => overdue_claims.count.to_s,
      "number_in_progress" => in_progress_claims.count.to_s,
      "number_not_started" => not_started_claims.count.to_s,
      "number_overall" => claims.count.to_s,
      "link_to_provider_dashboard" => "https://#{ENV["CANONICAL_HOSTNAME"]}/further-education-payments/providers/claims"
    }

    template_mail(
      FURTHER_EDUCATION_PAYMENTS[:PROVIDER_WEEKLY_UPDATE_TEMPLATE_ID],
      to: provider.email,
      reply_to_id: Policies::FurtherEducationPayments.notify_reply_to_id,
      personalisation: personalisation
    )
  end

  def provider_overdue_chaser
    claim = params[:claim]
    provider = claim.eligibility.provider_assigned_to
    expiry_date = Policies::FurtherEducationPayments.verification_due_date_for_claim(claim) + 3.weeks

    personalisation = {
      "provider_name" => provider.organisation_name,
      "claimant_name" => claim.full_name,
      "claim_reference" => claim.reference,
      "expiry_date" => expiry_date.to_fs(:long_date),
      "link_to_provider_dashboard" => "https://#{ENV["CANONICAL_HOSTNAME"]}/further-education-payments/providers/claims"
    }

    template_mail(
      FURTHER_EDUCATION_PAYMENTS[:PROVIDER_OVERDUE_CHASER_TEMPLATE_ID],
      to: provider.email,
      reply_to_id: Policies::FurtherEducationPayments.notify_reply_to_id,
      personalisation: personalisation
    )
  end

  private

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
