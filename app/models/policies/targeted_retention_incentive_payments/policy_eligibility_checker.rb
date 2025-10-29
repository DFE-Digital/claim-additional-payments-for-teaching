module Policies
  module TargetedRetentionIncentivePayments
    class PolicyEligibilityChecker
      attr_reader :answers

      delegate_missing_to :answers

      def initialize(answers:)
        @answers = answers
      end

      def policy
        Policies::TargetedRetentionIncentivePayments
      end

      def indicated_ineligible_itt_subject?
        return false if eligible_itt_subject.blank?

        TargetedRetentionIncentivePayments.fixed_subject_symbols.exclude?(
          eligible_itt_subject.to_sym
        )
      end

      def calculate_award_amount
        premium_payment_award&.award_amount
      end

      def ineligible?
        ineligibility_reason.present?
      end

      def ineligibility_reason
        return :policy_closed if policy_closed?

        return :school_ineligible if indicated_ineligible_school?

        if supply_teacher_lacking_either_long_contract_or_direct_employment?
          return :supply_teacher_contract_ineligible
        end

        return :poor_performance if poor_performance?

        return :ineligible_cohort if ineligible_cohort?

        return :insufficient_teaching if insufficient_teaching?

        if ineligible_itt_subject_and_no_relevant_degree?
          return :subject_and_degree_ineligible
        end

        :trainee_in_last_policy_year if trainee_in_last_policy_year?
      end

      private

      def policy_closed?
        policy.closed?(policy.current_academic_year)
      end

      def premium_payment_award
        return unless current_school.present?

        current_school.targeted_retention_incentive_payments_awards
          .by_academic_year(claim_year)
          .first
      end

      def indicated_ineligible_school?
        current_school.present? && !SchoolEligibility.new(current_school).eligible?
      end

      def supply_teacher_lacking_either_long_contract_or_direct_employment?
        return false unless employed_as_supply_teacher?

        has_entire_term_contract == false || employed_directly == false
      end

      def poor_performance?
        subject_to_formal_performance_action? || subject_to_disciplinary_action?
      end

      def ineligible_cohort?
        return false if itt_academic_year.nil?

        eligible_itt_years = policy.selectable_itt_years_for_claim_year(policy.current_academic_year)
        !itt_academic_year.in? eligible_itt_years
      end

      def insufficient_teaching?
        teaching_subject_now == false
      end

      def ineligible_itt_subject_and_no_relevant_degree?
        indicated_ineligible_itt_subject? && lacks_eligible_degree?
      end

      def lacks_eligible_degree?
        eligible_degree_subject == false
      end

      def trainee_in_last_policy_year?
        trainee_teacher? && policy.current_academic_year == TargetedRetentionIncentivePayments::POLICY_END_YEAR
      end
    end
  end
end
