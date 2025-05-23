module Policies
  module StudentLoans
    class PolicyEligibilityChecker
      attr_reader :answers

      def initialize(answers:)
        @answers = answers
      end

      def ineligible?
        ineligible_qts_award_year? ||
          ineligible_claim_school? ||
          employed_at_no_school? ||
          ineligible_current_school? ||
          not_taught_eligible_subjects? ||
          not_taught_enough? ||
          made_zero_repayments?
      end

      def ineligibility_reason
        [
          :ineligible_qts_award_year,
          :ineligible_claim_school,
          :employed_at_no_school,
          :ineligible_current_school,
          :not_taught_eligible_subjects,
          :not_taught_enough,
          :made_zero_repayments
        ].find { |eligibility_check| send(:"#{eligibility_check}?") }
      end

      def ineligible_qts_award_year?
        awarded_qualified_status_before_cut_off_date?
      end

      def awarded_qualified_status_before_cut_off_date?
        answers.qts_award_year.to_s == "before_cut_off_date"
      end

      private

      def claim_school
        @claim_school ||= answers.claim_school
      end

      def current_school
        @current_school ||= answers.current_school
      end

      def ineligible_claim_school?
        claim_school.present? && !claim_school.eligible_for_student_loans_as_claim_school?
      end

      def ineligible_current_school?
        current_school.present? && !current_school.eligible_for_student_loans_as_current_school?
      end

      def not_taught_eligible_subjects?
        answers.taught_eligible_subjects == false
      end

      def employed_at_no_school?
        answers.employment_status.to_s == "no_school"
      end

      def not_taught_enough?
        answers.mostly_performed_leadership_duties == true
      end

      # checks two scenarios: (1) they do not have a student loan, (2) they have a student loan but the repayment amount is zero
      def made_zero_repayments?
        return true if answers.has_student_loan == false

        answers.has_student_loan == true && answers.award_amount == 0
      end
    end
  end
end
