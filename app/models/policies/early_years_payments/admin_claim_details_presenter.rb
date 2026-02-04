module Policies
  module EarlyYearsPayments
    class AdminClaimDetailsPresenter
      include ActionView::Helpers::SanitizeHelper
      include Admin::PresenterMethods
      include Admin::ClaimsHelper
      include ActionView::Helpers::TextHelper
      include ActionView::Helpers::NumberHelper

      attr_reader :claim

      def initialize(claim)
        @claim = claim
      end

      def personal_details
        [
          ["Applicant name", personal_data(claim.full_name)],
          ["Date of birth", personal_data(formatted_date(claim.date_of_birth))],
          [translate("admin.national_insurance_number"), personal_data(claim.national_insurance_number)],
          ["Address", personal_data(sanitize(claim.address("<br>").html_safe, tags: %w[br]))],
          [translate("#{claim.policy.locale_key}.admin.email_address"), claim.email_address],
          [translate("#{claim.policy.locale_key}.admin.practitioner_email_address"), claim.practitioner_email_address],
          [translate("admin.mobile_number"), claim.mobile_number],
          [translate("#{claim.policy.locale_key}.admin.nursery_name"), claim.eligibility.eligible_ey_provider.nursery_name],
          [translate("#{claim.policy.locale_key}.admin.start_date"), formatted_date(claim.eligibility.start_date)],
          [translate("#{claim.policy.locale_key}.admin.paye_reference"), claim.paye_reference]
        ]
      end

      def provider_details
        [
          [translate("#{claim.policy.locale_key}.admin.provider_email_address"), claim.eligibility.provider_email_address],
          [translate("#{claim.policy.locale_key}.admin.provider_name"), claim.provider_contact_name],
          [translate("#{claim.policy.locale_key}.admin.consent_given"), "Confirmed"],
          [translate("#{claim.policy.locale_key}.admin.contract_type"), I18n.t(claim.eligibility.provider_entered_contract_type, scope: %w[early_years_payment_provider_authenticated.forms.contract_type.options])],
          [translate("#{claim.policy.locale_key}.admin.child_facing_confirmation_given"), display_boolean(claim.eligibility.child_facing_confirmation_given)],
          [translate("#{claim.policy.locale_key}.admin.returning_within_6_months"), display_boolean(claim.eligibility.returning_within_6_months)],
          [translate("#{claim.policy.locale_key}.admin.returner_worked_with_children"), display_boolean(claim.eligibility.returner_worked_with_children)],
          [translate("#{claim.policy.locale_key}.admin.returner_contract_type"), returner_contract_type_value]
        ]
      end

      def submission_details
        [
          [translate("early_years_payments.admin.started_at"), formatted_date(claim.started_at)],
          [translate("early_years_payments.admin.provider_submitted_at"), formatted_date(claim.eligibility.provider_claim_submitted_at)],
          [translate("early_years_payments.admin.practitioner_started_at"), formatted_date(claim.eligibility.practitioner_claim_started_at)],
          [translate("early_years_payments.admin.submitted_at"), formatted_date(claim.submitted_at)],
          [translate("admin.decision_deadline"), decision_deadline],
          [translate("admin.decision_overdue"), decision_overdue]
        ]
      end

      def policy_options_provided
        [
          [translate("early_years_payments.policy_full_name"), number_to_currency(claim.eligibility.award_amount, precision: 0)]
        ]
      end

      private

      def returner_contract_type_value
        return if claim.eligibility.returner_contract_type.blank?

        I18n.t(
          claim.eligibility.returner_contract_type.tr(" ", "_"),
          scope: %w[
            early_years_payment_provider_authenticated
            forms
            returner_contract_type
            options
          ]
        )
      end

      def personal_data(data)
        return personal_data_removed_text if claim.personal_data_removed?

        data
      end

      def formatted_date(date, format: nil)
        return unless date

        if format
          l(date, format: format)
        else
          l(date)
        end
      end

      def decision_overdue
        decision_deadline_warning(claim) if claim.submitted?
      end

      def decision_deadline
        formatted_date(claim.decision_deadline) if claim.submitted?
      end
    end
  end
end
