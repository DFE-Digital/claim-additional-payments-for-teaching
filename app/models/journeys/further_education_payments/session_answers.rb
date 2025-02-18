module Journeys
  module FurtherEducationPayments
    class SessionAnswers < Journeys::SessionAnswers
      attribute :teaching_responsibilities, :boolean, pii: false
      attribute :provision_search, :string, pii: false
      attribute :possible_school_id, :string, pii: false # GUID
      attribute :school_id, :string, pii: false # GUID
      attribute :contract_type, :string, pii: false
      attribute :fixed_term_full_year, :boolean, pii: false
      attribute :taught_at_least_one_term, :boolean, pii: false
      attribute :teaching_hours_per_week, :string, pii: false
      attribute :teaching_hours_per_week_next_term, :string, pii: false
      attribute :further_education_teaching_start_year, :string, pii: false
      attribute :subjects_taught, default: [], pii: false
      attribute :building_construction_courses, default: [], pii: false
      attribute :chemistry_courses, default: [], pii: false
      attribute :computing_courses, default: [], pii: false
      attribute :early_years_courses, default: [], pii: false
      attribute :engineering_manufacturing_courses, default: [], pii: false
      attribute :maths_courses, default: [], pii: false
      attribute :physics_courses, default: [], pii: false
      attribute :hours_teaching_eligible_subjects, :boolean, pii: false
      attribute :teaching_qualification, :string, pii: false
      attribute :subject_to_formal_performance_action, :boolean, pii: false
      attribute :subject_to_disciplinary_action, :boolean, pii: false
      attribute :half_teaching_hours, :boolean, pii: false
      attribute :award_amount, :decimal, pii: false

      def policy
        Policies::FurtherEducationPayments
      end

      def school
        return unless school_id

        @school ||= School.find(school_id)
      end

      def possible_school
        return unless possible_school_id

        @possible_school ||= School.find(possible_school_id)
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

      def eligible_fe_provider?
        return unless school

        @eligible_fe_provider ||= EligibleFeProvider
          .by_academic_year(AcademicYear.current)
          .where(ukprn: school.ukprn)
          .exists?
      end

      def ineligible_fe_provider?
        return unless school

        !eligible_fe_provider?
      end

      def fe_provider_closed?
        return unless school

        school.closed?
      end

      def all_selected_courses_ineligible?
        groups = subjects_taught.reject { |e| e == "none" }

        return if groups.empty?

        groups.all? do |subject|
          public_send(:"#{subject}_courses").include?("none")
        end
      end

      def less_than_half_hours_teaching_eligible_courses?
        hours_teaching_eligible_subjects == false
      end

      def calculate_award_amount
        case teaching_hours_per_week
        when "more_than_12"
          school.eligible_fe_provider.max_award_amount
        when "between_2_5_and_12"
          school.eligible_fe_provider.lower_award_amount
        else
          0
        end
      end

      def performing_poorly?
        subject_to_formal_performance_action || subject_to_disciplinary_action
      end
    end
  end
end
