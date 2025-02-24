module Journeys
  module TargetedRetentionIncentivePayments
    class SessionAnswers < Journeys::SessionAnswers
      attribute :employed_as_supply_teacher, :boolean, pii: false
      attribute :subject_to_formal_performance_action, :boolean, pii: false
      attribute :subject_to_disciplinary_action, :boolean, pii: false
      attribute :itt_academic_year_string, :string, pii: false
      attribute :teaching_subject_now, :boolean, pii: false
      attribute :eligible_itt_subject, :string, pii: false
      attribute :induction_completed, :boolean, pii: false
      attribute :nqt_in_academic_year_after_itt, :boolean, pii: false
      attribute :has_entire_term_contract, :boolean, pii: false
      attribute :employed_directly, :boolean, pii: false
      attribute :qualification, :string, pii: false
      attribute :eligible_degree_subject, :boolean, pii: false

      # `PolicyEligibilityChecker≥#no_selectable_subjects?` returns early if
      # there is no academic year, handling cases where the claimant is yet to
      # answers the itt_academic_year question.
      #
      # FIXME RL: make this more explicit in the eligibility checker
      def itt_academic_year
        return unless itt_academic_year_string.present?

        if itt_academic_year_string == NONE_OF_THE_ABOVE_ACADEMIC_YEAR
          AcademicYear.none
        else
          AcademicYear.new(itt_academic_year_string)
        end
      end

      def trainee_teacher?
        nqt_in_academic_year_after_itt == false
      end
    end
  end
end
