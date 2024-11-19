module Policies
  module LevellingUpPremiumPayments
    class PolicyEligibilityChecker
      include EligibilityCheckable

      attr_reader :answers

      delegate_missing_to :answers

      def initialize(answers:)
        @answers = answers
      end

      def policy
        Policies::LevellingUpPremiumPayments
      end

      def indicated_ineligible_itt_subject?
        return false if eligible_itt_subject.blank?

        if claim_year.blank? || itt_academic_year.blank?
          # trainee teacher who won't have given their ITT year
          eligible_itt_subject.present? && LevellingUpPremiumPayments.fixed_subject_symbols.exclude?(eligible_itt_subject.to_sym)
        else
          LevellingUpPremiumPayments.subject_symbols(
            claim_year: claim_year,
            itt_year: itt_academic_year
          ).exclude?(eligible_itt_subject.to_sym)
        end
      end

      def calculate_award_amount
        premium_payment_award&.award_amount
      end

      private

      def premium_payment_award
        return unless current_school.present?

        current_school.levelling_up_premium_payments_awards.find_by(
          academic_year: claim_year.to_s
        )
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
          eligible_itt_subject.present? && eligible_itt_subject.to_sym.in?(Policies::LevellingUpPremiumPayments.fixed_subject_symbols)
        else
          LevellingUpPremiumPayments.current_subject_symbols(
            claim_year: claim_year,
            itt_year: itt_academic_year
          ).include?(eligible_itt_subject.to_sym)
        end
      end

      def eligible_degree?
        eligible_degree_subject?
      end

      def specific_ineligible_attributes?
        indicated_ecp_only_itt_subject? || trainee_teacher_with_ineligible_itt_subject? || ineligible_itt_subject_and_no_relevant_degree?
      end

      def trainee_teacher_with_ineligible_itt_subject?
        trainee_teacher? && indicated_ineligible_itt_subject?
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
