module Policies
  module FurtherEducationPayments
    class PolicyEligibilityChecker
      attr_reader :answers

      delegate_missing_to :answers

      def initialize(answers:)
        @answers = answers
      end

      def ineligible?
        ineligibility_reason.present?
      end

      def ineligibility_reason
        if answers.teaching_responsibilities == false
          :lack_teaching_responsibilities
        elsif answers.ineligible_fe_provider? || answers.fe_provider_closed?
          :fe_provider
        elsif answers.taught_at_least_one_term == false
          :must_teach_at_least_one_term
        elsif !answers.recent_further_education_teacher?
          :must_be_recent_further_education_teacher
        elsif answers.teaching_less_than_2_5_hours_per_week?
          :teaching_less_than_2_5
        elsif answers.teaching_less_than_2_5_hours_per_week_next_term?
          :teaching_less_than_2_5_next_term
        elsif answers.subject_to_problematic_actions?
          :subject_to_problematic_actions
        elsif answers.lacks_teacher_qualification_or_enrolment?
          :lacks_teacher_qualification_or_enrolment
        elsif answers.less_than_half_hours_teaching_fe?
          :must_at_least_half_hours_teaching_fe
        elsif answers.subjects_taught.include? "none"
          :subject
        elsif answers.all_selected_courses_ineligible?
          :courses
        elsif answers.less_than_half_hours_teaching_eligible_courses?
          :less_than_half_hours_teaching_eligible_courses
        end
      end
    end
  end
end
