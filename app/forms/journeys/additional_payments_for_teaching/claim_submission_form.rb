module Journeys
  module AdditionalPaymentsForTeaching
    class ClaimSubmissionForm < ::ClaimSubmissionBaseForm
      ELIGIBILITY_ATTRIBUTES = [
        [:nqt_in_academic_year_after_itt, :boolean],
        [:employed_as_supply_teacher, :boolean],
        [:qualification, :string],
        [:has_entire_term_contract, :boolean],
        [:employed_directly, :boolean],
        [:subject_to_disciplinary_action, :boolean],
        [:subject_to_formal_performance_action, :boolean],
        [:eligible_itt_subject, :string],
        [:eligible_degree_subject, :string],
        [:teaching_subject_now, :boolean],
        [:itt_academic_year, AcademicYear::Type.new],
        [:current_school_id, :string], # uuid
        [:induction_completed, :boolean],
        [:school_somewhere_else, :boolean]
      ]

      ELIGIBILITY_ATTRIBUTES.each do |name, type|
        attribute name, type
      end

      private

      def eligibility_attribute_names
        ELIGIBILITY_ATTRIBUTES.map(&:first)
      end

      def selected_claim_policy
        if selected_policy.present?
          "Policies::#{selected_policy}".constantize
        end
      end

      def main_eligibility
        @main_eligibility ||= eligibilities.detect { |e| e.policy == main_policy }
      end

      def main_policy
        if selected_claim_policy.present?
          selected_claim_policy
        else
          Policies::EarlyCareerPayments
        end
      end

      def calculate_award_amount(eligibility)
        eligibility.award_amount = eligibility.calculate_award_amount
      end

      def generate_policy_options_provided
        eligible_now_and_sorted.map do |e|
          {
            "policy" => e.policy.to_s,
            "award_amount" => BigDecimal(e.award_amount)
          }
        end
      end

      def eligible_now_and_sorted
        eligible_now.sort_by { |e| [-e.award_amount.to_i, e.policy.short_name] }
      end

      def eligible_now
        eligibilities.select { |e| e.status == :eligible_now }
      end

      def i18n_namespace
        I18N_NAMESPACE
      end
    end
  end
end
