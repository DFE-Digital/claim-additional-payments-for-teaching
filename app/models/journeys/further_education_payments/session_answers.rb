module Journeys
  module FurtherEducationPayments
    class SessionAnswers < Journeys::SessionAnswers
      attribute :teaching_responsibilities, :boolean
      attribute :provision_search, :string
      attribute :school_id, :string # GUID
      attribute :contract_type, :string
      attribute :fixed_term_full_year, :boolean
      attribute :taught_at_least_one_term, :boolean
      attribute :teaching_hours_per_week, :string
      attribute :teaching_hours_per_week_next_term, :string
      attribute :further_education_teaching_start_year, :string
      attribute :subjects_taught, default: []
      attribute :building_construction_courses, default: []
      attribute :chemistry_courses, default: []
      attribute :computing_courses, default: []
      attribute :early_years_courses, default: []
      attribute :engineering_manufacturing_courses, default: []
      attribute :maths_courses, default: []
      attribute :physics_courses, default: []
      attribute :teaching_qualification, :string
      attribute :subject_to_formal_performance_action, :boolean
      attribute :subject_to_disciplinary_action, :boolean
      attribute :half_teaching_hours, :boolean

      def policy
        Policies::FurtherEducationPayments
      end

      def school
        @school ||= School.find(school_id)
      end

      def teaching_responsibilities?
        !!teaching_responsibilities
      end

      def half_teaching_hours?
        !!half_teaching_hours
      end

      def subject_to_formal_performance_action?
        !!subject_to_formal_performance_action
      end

      def subject_to_disciplinary_action?
        !!subject_to_disciplinary_action
      end

      def recent_further_education_teacher?
        !further_education_teaching_start_year&.start_with?("pre-")
      end

      def teaching_less_than_2_5_hours_per_week?
        teaching_hours_per_week == "less_than_2_5"
      end

      def teaching_less_than_2_5_hours_per_week_next_term?
        teaching_hours_per_week_next_term == "less_than_2_5"
      end

      def subject_to_problematic_actions?
        subject_to_formal_performance_action || subject_to_disciplinary_action
      end

      def lacks_teacher_qualification_or_enrolment?
        teaching_qualification == "no_not_planned"
      end

      def less_than_half_hours_teaching_fe?
        half_teaching_hours == false
      end
    end
  end
end
