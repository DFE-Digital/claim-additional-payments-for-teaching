module Policies
  module EarlyCareerPayments
    class PolicyEligibilityChecker
      include EligibilityCheckable

      attr_reader :answers

      delegate_missing_to :answers

      def initialize(answers:)
        @answers = answers
      end

      def policy
        Policies::EarlyCareerPayments
      end

      def induction_not_completed?
        !induction_completed.nil? && !induction_completed?
      end

      def ecp_only_school?
        Policies::EarlyCareerPayments::SchoolEligibility.new(current_school).eligible? &&
          !Policies::LevellingUpPremiumPayments::SchoolEligibility.new(current_school).eligible?
      end

      def calculate_award_amount
        return 0 if eligible_itt_subject.blank?

        args = {policy_year: claim_year, itt_year: itt_academic_year, subject_symbol: eligible_itt_subject.to_sym, school: current_school}

        if args.values.any?(&:blank?)
          0
        else
          Policies::EarlyCareerPayments::AwardAmountCalculator.new(**args).amount_in_pounds
        end
      end

      private

      def specific_eligible_now_attributes?
        induction_completed? && itt_subject_eligible_now?
      end

      def itt_subject_eligible_now?
        itt_subject = eligible_itt_subject # attribute name implies eligibility which isn't always the case
        return false if itt_subject.blank?
        return false if itt_subject_none_of_the_above?

        itt_subject_checker = JourneySubjectEligibilityChecker.new(claim_year: claim_year, itt_year: itt_academic_year)
        itt_subject.to_sym.in?(itt_subject_checker.current_subject_symbols(policy))
      end

      def specific_ineligible_attributes?
        trainee_teacher? || (induction_not_completed? && !any_future_policy_years?) || itt_subject_ineligible_now_and_in_the_future?
      end

      def itt_subject_ineligible_now_and_in_the_future?
        itt_subject = eligible_itt_subject # attribute name implies eligibility which isn't always the case
        return false if itt_subject.blank?
        return true if itt_subject_none_of_the_above?

        itt_subject_checker = JourneySubjectEligibilityChecker.new(claim_year: claim_year, itt_year: itt_academic_year)
        !itt_subject.to_sym.in?(itt_subject_checker.current_and_future_subject_symbols(policy))
      end

      def specific_eligible_later_attributes?
        newly_qualified_teacher? && ((induction_not_completed? && any_future_policy_years?) || (!itt_subject_eligible_now? && itt_subject_eligible_later?))
      end

      def itt_subject_eligible_later?
        itt_subject = eligible_itt_subject # attribute name implies eligibility which isn't always the case
        return false if itt_subject.blank?
        return false if itt_subject_none_of_the_above?

        itt_subject_checker = JourneySubjectEligibilityChecker.new(claim_year: claim_year, itt_year: itt_academic_year)
        itt_subject.to_sym.in?(itt_subject_checker.future_subject_symbols(policy))
      end

      # TODO: Is this used anywhere?
      def itt_subject_ineligible?
        return false if claim_year.blank?

        itt_subject_other_than_those_eligible_now_or_in_the_future?
      end

      def itt_subject_other_than_those_eligible_now_or_in_the_future?
        itt_subject = eligible_itt_subject # attribute name implies eligibility which isn't always the case
        return false if itt_subject.blank?

        args = {claim_year: claim_year, itt_year: itt_academic_year}

        if args.any?(&:blank?)
          # can still rule some out
          itt_subject_none_of_the_above?
        else
          itt_subject_checker = JourneySubjectEligibilityChecker.new(**args)
          itt_subject_symbol = itt_subject.to_sym
          !itt_subject_symbol.in?(itt_subject_checker.current_and_future_subject_symbols(policy))
        end
      end
    end
  end
end
