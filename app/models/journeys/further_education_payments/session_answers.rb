module Journeys
  module FurtherEducationPayments
    class SessionAnswers < Journeys::SessionAnswers
      attribute :teaching_responsibilities, :boolean, pii: false
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

      attribute :work_email_access, :boolean, pii: false
      attribute :work_email, :string, pii: true
      attribute :work_email_otp_secret, :string, pii: true
      attribute :work_email_otp_timestamp, :datetime, pii: true
      attribute :work_email_verified, :boolean, pii: false

      attribute :award_amount, :decimal, pii: false
      attribute :valid_passport, :boolean, pii: false
      attribute :passport_number, :string, pii: true

      attribute :check_your_answers_part_one_completed, :boolean, pii: false

      attribute :claimant_declaration, :boolean, pii: false

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

        @eligible_fe_provider ||= Policies::FurtherEducationPayments::EligibleFeProvider
          .by_academic_year(Journeys::FurtherEducationPayments.configuration.current_academic_year)
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
        provider = school.eligible_fe_provider(academic_year: Journeys::FurtherEducationPayments.configuration.current_academic_year)
        case teaching_hours_per_week
        when "more_than_20"
          provider.max_award_amount
        when "more_than_12"
          provider.middle_award_amount
        when "between_2_5_and_12"
          provider.lower_award_amount
        else
          0
        end
      end

      def claim_already_submitted_this_policy_year?
        existing_claim_this_window.present?
      end

      def existing_claim_this_window
        @previous_claim ||= one_login_account
          .claims
          .by_policy(Policies::FurtherEducationPayments)
          .by_academic_year(Journeys::FurtherEducationPayments.configuration.current_academic_year)
          .where.not(onelogin_uid: nil)
          .where.not(id: submitted_claim_id)
          .first
      end

      def exceeded_teaching_years_from_previous_claim?
        return false if approved_previous_claim.nil?

        start_year = AcademicYear.new(approved_previous_claim.eligibility.further_education_teaching_start_year)
        start_year <= Journeys::FurtherEducationPayments.configuration.current_academic_year - 5
      end

      private

      def one_login_account
        @one_login_account ||= OneLoginAccount.new(uid: onelogin_uid)
      end

      def approved_previous_claim
        @approved_previous_claim ||= one_login_account
          .claims
          .by_policy(Policies::FurtherEducationPayments)
          .by_academic_year(Journeys::FurtherEducationPayments.configuration.current_academic_year.previous)
          .where.not(onelogin_uid: nil)
          .approved
          .first
      end
    end
  end
end
