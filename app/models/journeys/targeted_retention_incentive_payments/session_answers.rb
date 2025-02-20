module Journeys
  module TargetedRetentionIncentivePayments
    class SessionAnswers < Journeys::SessionAnswers
      attribute :school_somewhere_else, :boolean, pii: false
      attribute :employed_as_supply_teacher, :boolean, pii: false
      attribute :subject_to_formal_performance_action, :boolean, pii: false
      attribute :subject_to_disciplinary_action, :boolean, pii: false
      attribute :itt_academic_year, AcademicYear::Type.new, pii: false
      attribute :teaching_subject_now, :boolean, pii: false
      attribute :eligible_itt_subject, :string, pii: false
      attribute :induction_completed, :boolean, pii: false
      attribute :nqt_in_academic_year_after_itt, :boolean, pii: false
      attribute :has_entire_term_contract, :boolean, pii: false
      attribute :employed_directly, :boolean, pii: false
      attribute :qualification, :string, pii: false
      attribute :qualifications_details_check, :boolean, pii: false
      attribute :eligible_degree_subject, :boolean, pii: false
      attribute :award_amount, :decimal, pii: false

      def trainee_teacher?
        nqt_in_academic_year_after_itt == false
      end

      def trainee_teacher=(value)
        self.nqt_in_academic_year_after_itt = !value
      end

      def teaching_physics_or_chemistry?
        eligible_itt_subject == "physics" || eligible_itt_subject == "chemistry"
      end

      def set_by_teacher_id?(attr)
        return false unless logged_in_with_tid?
        return false unless details_check?

        teacher_id_user_info[attr].present?
      end

      def personal_details_set_by_tid?
        return false unless logged_in_with_tid? && details_check?

        PersonalDetailsForm.new(
          journey_session: session,
          journey: Journeys::TargetedRetentionIncentivePayments,
          params: ActionController::Parameters.new
        ).valid?
      end

      # User has either selected to skip the provide mobile screen or we have
      # their mobile from TID and they don't want to use it.
      def doesnt_want_to_provide_mobile_number?
        provide_mobile_number == false || mobile_check == "declined"
      end

      def chose_recent_tps_school?
        school_somewhere_else == false
      end

      # For information_provided.html.erb
      def selected_claim_policy
        policy
      end

      def policy
        Policies::TargetedRetentionIncentivePayments
      end

      def dqt_record
        return unless dqt_teacher_status.present?

        @dqt_record ||= Policies::TargetedRetentionIncentivePayments::DqtRecord.new(
          Dqt::Teacher.new(dqt_teacher_status),
          self
        )
      end

      def dqt_qualification
        return nil unless dqt_record && details_check?

        dqt_record.route_into_teaching
      end

      def dqt_itt_academic_year
        return nil unless dqt_record && details_check?
        return nil unless dqt_record.academic_date

        AcademicYear.for(dqt_record.academic_date)
      end

      def dqt_eligible_itt_subject
        return nil unless dqt_record && details_check?

        dqt_record.eligible_itt_subject_for_claim
      end

      def dqt_eligible_degree_subject?
        return false unless dqt_record && details_check?

        dqt_record.eligible_degree_code?
      end

      def dqt_show_degree_subjects?
        return false unless dqt_record

        return false unless dqt_eligible_itt_subject == :none_of_the_above

        dqt_degree_subjects.any?
      end

      def dqt_degree_subjects
        return [] unless dqt_record

        # Often the DQT record will represent subject names in all lowercase
        dqt_record.degree_names.map(&:titleize)
      end

      def dqt_academic_date
        AcademicYear.for(dqt_record.academic_date)
      end

      def dqt_itt_subjects
        return [] unless dqt_record

        dqt_record.itt_subjects.map(&:titleize)
      end
    end
  end
end
