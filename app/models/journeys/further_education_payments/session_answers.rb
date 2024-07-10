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
      attribute :teaching_qualification, :string
      attribute :subject_to_formal_performance_action, :boolean
      attribute :subject_to_disciplinary_action, :boolean
      attribute :half_teaching_hours, :boolean

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
    end
  end
end
