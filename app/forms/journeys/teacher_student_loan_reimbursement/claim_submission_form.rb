module Journeys
  module TeacherStudentLoanReimbursement
    class ClaimSubmissionForm < ::ClaimSubmissionBaseForm
      ELIGIBILITY_ATTRIBUTES = [
        [:qts_award_year, :string],
        [:claim_school_id, :string], # uuid
        [:current_school_id, :string], # uuid
        [:employment_status, :string],
        [:biology_taught, :boolean],
        [:chemistry_taught, :boolean],
        [:computing_taught, :boolean],
        [:languages_taught, :boolean],
        [:physics_taught, :boolean],
        [:taught_eligible_subjects, :boolean],
        [:student_loan_repayment_amount, :decimal],
        [:had_leadership_position, :boolean],
        [:mostly_performed_leadership_duties, :boolean],
        [:claim_school_somewhere_else, :boolean]
      ]

      ELIGIBILITY_ATTRIBUTES.each do |name, type|
        attribute name, type
      end

      private

      def eligibility_attribute_names
        ELIGIBILITY_ATTRIBUTES.map(&:first)
      end

      def main_eligibility
        @main_eligibility ||= eligibilities.first
      end

      def calculate_award_amount(eligibility)
        # NOOP
      end

      def generate_policy_options_provided
        []
      end

      def i18n_namespace
        I18N_NAMESPACE
      end
    end
  end
end
