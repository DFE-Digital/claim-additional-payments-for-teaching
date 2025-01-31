class ClaimMailer < ApplicationMailer
  include ClaimMailerHelper
  include AdditionalPaymentsHelper
  helper :application

  def submitted(claim)
    unknown_policy_check(claim)
    set_common_instance_variables(claim)
    personalisation = {
      first_name: @claim.first_name,
      ref_number: @claim.reference,
      support_email_address: @support_email_address
    }

    send_mail(template_ids(claim)[:CLAIM_RECEIVED_NOTIFY_TEMPLATE_ID], personalisation)
  end

  def approved(claim)
    unknown_policy_check(claim)
    set_common_instance_variables(claim)
    personalisation = {
      first_name: @claim.first_name,
      ref_number: @claim.reference,
      support_email_address: @support_email_address
    }

    send_mail(template_ids(claim)[:CLAIM_APPROVED_NOTIFY_TEMPLATE_ID], personalisation)
  end

  def rejected(claim)
    unknown_policy_check(claim)
    set_common_instance_variables(claim)
    personalisation = {
      first_name: @claim.first_name,
      ref_number: @claim.reference,
      support_email_address: @support_email_address,
      current_financial_year: (claim.policy == Policies::StudentLoans) ? Policies::StudentLoans.current_financial_year : "",
      last_academic_year: rejected_reason_claimed_last_year? ? (AcademicYear.current - 1).to_s : "",
      **rejected_reasons_personalisation(@claim.latest_decision&.rejected_reasons_hash)
    }

    send_mail(template_ids(claim)[:CLAIM_REJECTED_NOTIFY_TEMPLATE_ID], personalisation)
  end

  def rejected_provider_notification(claim)
    unknown_policy_check(claim)
    set_common_instance_variables(claim)

    personalisation = {
      nursery_name: claim.eligibility.eligible_ey_provider.nursery_name,
      ref_number: claim.reference,
      practitioner_name: claim.eligibility.practitioner_name,
      support_email_address: @support_email_address,
      **rejected_reasons_personalisation(@claim.latest_decision&.rejected_reasons_hash)
    }

    template_mail(
      "0c345721-c8d6-493a-95b7-006e84ba9c4e",
      to: @claim.eligibility.eligible_ey_provider.primary_key_contact_email_address,
      reply_to_id: @policy.notify_reply_to_id,
      personalisation:
    )
  end

  def update_after_three_weeks(claim)
    unknown_policy_check(claim)
    set_common_instance_variables(claim)

    personalisation = {
      first_name: @claim.first_name,
      ref_number: @claim.reference,
      support_email_address: @support_email_address,
      application_date: l(@claim.submitted_at.to_date)
    }

    send_mail(template_ids(claim)[:CLAIM_UPDATE_AFTER_THREE_WEEKS_NOTIFY_TEMPLATE_ID], personalisation)
  end

  def email_verification(claim, one_time_password, journey_name)
    unknown_policy_check(claim)
    set_common_instance_variables(claim)
    @subject = "#{@claim_subject} email verification"
    @one_time_password = one_time_password
    personalisation = {
      email_subject: @subject,
      first_name: @claim.first_name,
      one_time_password: @one_time_password,
      support_email_address: @support_email_address,
      validity_duration: one_time_password_validity_duration,
      journey_name:
    }

    send_mail(OTP_EMAIL_NOTIFY_TEMPLATE_ID, personalisation)
  end

  def early_years_payment_provider_email(claim, one_time_password, email)
    unknown_policy_check(claim)
    set_common_instance_variables(claim)
    @magic_link = early_years_payment_provider_magic_link(one_time_password, email)
    personalisation = {
      magic_link: @magic_link
    }

    if Rails.env.development?
      Rails.logger.info("\n\nEmail verification code: #{one_time_password}\n")
    end

    send_mail(template_ids(claim)[:CLAIM_PROVIDER_EMAIL_TEMPLATE_ID], personalisation)
  end

  def early_years_payment_practitioner_email(claim)
    policy_check!(claim, Policies::EarlyYearsPayments)

    personalisation = {
      full_name: claim.full_name,
      setting_name: claim.eligibility.eligible_ey_provider.nursery_name,
      ref_number: claim.reference,
      complete_claim_url: early_years_practitioner_invite_link(claim:)
    }

    template_id = template_ids(claim)[:CLAIM_PRACTITIONER_NOTIFY_TEMPLATE_ID]

    template_mail(
      template_id,
      to: claim.practitioner_email_address,
      reply_to_id: claim.policy.notify_reply_to_id,
      personalisation: personalisation
    )
  end

  def further_education_payment_provider_verification_email(claim)
    policy_check!(claim, Policies::FurtherEducationPayments)

    personalisation = {
      recipient_name: claim.school.name,
      claimant_name: claim.full_name,
      claim_reference: claim.reference,
      claim_submission_date: l(claim.created_at.to_date),
      verification_due_date: l(Policies::FurtherEducationPayments.verification_due_date_for_claim(claim)),
      verification_url: Journeys::FurtherEducationPayments::Provider::SlugSequence.verify_claim_url(claim)
    }

    template_id = template_ids(claim)[:CLAIM_PROVIDER_VERIFICATION_EMAIL_TEMPLATE_ID]

    template_mail(
      template_id,
      to: claim.school.eligible_fe_provider.primary_key_contact_email_address,
      personalisation: personalisation
    )
  end

  def further_education_payment_provider_verification_chase_email(claim)
    policy_check!(claim, Policies::FurtherEducationPayments)

    personalisation = {
      recipient_name: claim.school.name,
      claimant_name: claim.full_name,
      claim_reference: claim.reference,
      claim_submission_date: l(claim.created_at.to_date),
      verification_due_date: l(Policies::FurtherEducationPayments.verification_chase_due_date_for_claim(claim)),
      verification_url: Journeys::FurtherEducationPayments::Provider::SlugSequence.verify_claim_url(claim)
    }

    template_id = template_ids(claim)[:CLAIM_PROVIDER_VERIFICATION_CHASE_EMAIL_TEMPLATE_ID]

    template_mail(
      template_id,
      to: claim.school.eligible_fe_provider.primary_key_contact_email_address,
      personalisation: personalisation
    )
  end

  def further_education_payment_provider_confirmation_email(claim)
    policy_check!(claim, Policies::FurtherEducationPayments)

    verification = claim.eligibility.verification

    verifier = verification.fetch("verifier")
    verifier_name = "#{verifier.fetch("first_name")} #{verifier.fetch("last_name")}"
    verification_date = verification.fetch("created_at").to_date

    personalisation = {
      recipient_name: claim.school.name,
      claim_reference: claim.reference,
      claimant_name: claim.full_name,
      verifier_name: verifier_name,
      verification_date: l(verification_date)
    }

    template_id = template_ids(claim)[:CLAIM_PROVIDER_VERIFICATION_CONFIRMATION_EMAIL_TEMPLATE_ID]

    template_mail(
      template_id,
      to: claim.school.eligible_fe_provider.primary_key_contact_email_address,
      personalisation: personalisation
    )
  end

  private

  def set_common_instance_variables(claim)
    @claim = claim
    @claim_description = translate("#{@claim.policy.locale_key}.claim_description")
    @claim_subject = translate("#{@claim.policy.locale_key}.claim_subject")
    @display_name = [@claim.first_name, @claim.surname].join(" ")
    @policy = @claim.policy
    @support_email_address = translate("#{@claim.policy.locale_key}.support_email_address")
  end

  def template_ids(claim)
    "ApplicationMailer::#{claim.policy.to_s.underscore.upcase}".safe_constantize
  end

  def send_mail(template_id, personalisation)
    if Rails.env.development?
      Rails.logger.info(
        [
          "\n",
          "Sending email to: #{@claim.email_address}",
          "Template ID: #{template_id}",
          "Subject: #{@subject}",
          "Personalisation: \n#{personalisation.pretty_inspect}"
        ].join("\n")
      )
    end

    template_mail(
      template_id,
      to: @claim.email_address,
      subject: @subject,
      reply_to_id: @policy.notify_reply_to_id,
      personalisation:
    )
  end

  def unknown_policy_check(claim)
    return if [
      Policies::StudentLoans,
      Policies::EarlyCareerPayments,
      Policies::TargetedRetentionIncentivePayments,
      Policies::InternationalRelocationPayments,
      Policies::FurtherEducationPayments,
      Policies::EarlyYearsPayments
    ].include?(claim.policy)
    raise ArgumentError, "Unknown claim policy: #{claim.policy}"
  end

  def early_years_payment_provider_magic_link(one_time_password, email)
    "https://#{ENV["CANONICAL_HOSTNAME"]}/#{Journeys::EarlyYearsPayment::Provider::Authenticated::ROUTING_NAME}/claim?code=#{one_time_password}&email=#{email}"
  end

  def early_years_practitioner_invite_link(claim:)
    "https://#{ENV["CANONICAL_HOSTNAME"]}/#{Journeys::EarlyYearsPayment::Practitioner::ROUTING_NAME}/find-reference?skip_landing_page=true"
  end

  def policy_check!(claim, policy)
    return if claim.policy == policy

    raise(
      ArgumentError,
      "Claim policy does not match the expected policy `#{policy}`"
    )
  end
end
