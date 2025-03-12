module Policies
  module TargetedRetentionIncentivePayments
    class PolicyEligibilityChecker
      include EligibilityCheckable

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

        if claim_year.blank? || itt_academic_year.blank?
          # trainee teacher who won't have given their ITT year
          eligible_itt_subject.present? && TargetedRetentionIncentivePayments.fixed_subject_symbols.exclude?(eligible_itt_subject.to_sym)
        else
          TargetedRetentionIncentivePayments.subject_symbols(
            claim_year: claim_year,
            itt_year: itt_academic_year
          ).exclude?(eligible_itt_subject.to_sym)
        end
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

        return :no_selectable_subjects if no_selectable_subjects?

        return :ineligible_cohort if ineligible_cohort?

        return :insufficient_teaching if insufficient_teaching?

        return :subject_invalid_for_tslr if indicated_ecp_only_itt_subject?

        if ineligible_itt_subject_and_no_relevant_degree?
          :subject_and_degree_ineligible
        end
      end

      private

      def premium_payment_award
        return unless current_school.present?

        current_school.targeted_retention_incentive_payments_awards
          .by_academic_year(claim_year)
          .first
      end

      def indicated_ecp_only_itt_subject?
        eligible_itt_subject.present? && (eligible_itt_subject.to_sym == :foreign_languages)
      end

      def specific_eligible_now_attributes?
        eligible_itt_subject_or_relevant_degree?
      end

      def eligible_itt_subject_or_relevant_degree?
        good_itt_subject? || eligible_degree?
      end

      def good_itt_subject?
        return false if eligible_itt_subject.blank?

        if claim_year.blank? || itt_academic_year.blank?
          # trainee teacher who won't have given their ITT year
          eligible_itt_subject.present? && eligible_itt_subject.to_sym.in?(Policies::TargetedRetentionIncentivePayments.fixed_subject_symbols)
        else
          TargetedRetentionIncentivePayments.current_subject_symbols(
            claim_year: claim_year,
            itt_year: itt_academic_year
          ).include?(eligible_itt_subject.to_sym)
        end
      end

      def eligible_degree?
        eligible_degree_subject?
      end

      def specific_ineligible_attributes?
        indicated_ecp_only_itt_subject? || ineligible_itt_subject_and_no_relevant_degree?
      end

      def ineligible_itt_subject_and_no_relevant_degree?
        indicated_ineligible_itt_subject? && lacks_eligible_degree?
      end

      def specific_eligible_later_attributes?
        trainee_teacher? && eligible_itt_subject_or_relevant_degree?
      end

      def lacks_eligible_degree?
        eligible_degree_subject == false
      end
    end
  end
end
