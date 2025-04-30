# frozen_string_literal: true

module Journeys
  module AdditionalPaymentsForTeaching
    extend Base
    extend self

    ROUTING_NAME = "additional-payments"
    VIEW_PATH = "additional_payments"
    I18N_NAMESPACE = "additional_payments"
    POLICIES = [Policies::EarlyCareerPayments, Policies::TargetedRetentionIncentivePayments]
    FORMS = {
      "claims" => {}
    }.freeze

    def policies
      if FeatureFlag.enabled?(:tri_only_journey)
        [Policies::EarlyCareerPayments]
      else
        POLICIES
      end
    end

    def set_a_reminder?(itt_academic_year:, policy:)
      policy_year = configuration.current_academic_year
      return false if policy_year >= policy::POLICY_END_YEAR

      next_year = policy_year + 1
      eligible_itt_years = selectable_itt_years_for_claim_year(next_year)
      eligible_itt_years.include?(itt_academic_year)
    end

    def requires_student_loan_details?
      true
    end

    def selectable_itt_years_for_claim_year(claim_year)
      policies.flat_map do |policy|
        policy.selectable_itt_years_for_claim_year(claim_year)
      end.uniq
    end

    def uses_reminders?
      true
    end
  end
end
