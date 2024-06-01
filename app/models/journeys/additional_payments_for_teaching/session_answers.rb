module Journeys
  module AdditionalPaymentsForTeaching
    class SessionAnswers < Journeys::SessionAnswers
      attribute :employed_as_supply_teacher, :boolean
      attribute :qualification, :string
      attribute :has_entire_term_contract, :boolean
      attribute :employed_directly, :boolean
      attribute :subject_to_disciplinary_action, :boolean
      attribute :subject_to_formal_performance_action, :boolean
      attribute :eligible_itt_subject, :string
      attribute :teaching_subject_now, :boolean
      attribute :itt_academic_year, AcademicYear::Type.new
      attribute :induction_completed, :boolean
      attribute :school_somewhere_else, :boolean
      attribute :nqt_in_academic_year_after_itt, :boolean
      attribute :eligible_degree_subject, :boolean

      def early_career_payments_dqt_teacher_record
        return unless dqt_teacher_status.present?

        @early_career_payments_dqt_teacher_record ||= Policies::EarlyCareerPayments::DqtRecord.new(
          Dqt::Teacher.new(dqt_teacher_status),
          self
        )
      end

      def levelling_up_premium_payments_dqt_reacher_record
        return unless dqt_teacher_status.present?

        @levelling_up_premium_payments_dqt_reacher_record ||= Policies::LevellingUpPremiumPayments::DqtRecord.new(
          Dqt::Teacher.new(dqt_teacher_status),
          self
        )
      end

      def has_no_dqt_data_for_claim?
        dqt_teacher_status.blank? ||
          levelling_up_premium_payments_dqt_reacher_record.has_no_data_for_claim? ||
          early_career_payments_dqt_teacher_record.has_no_data_for_claim?
      end

      def policy
        if selected_policy.present?
          selected_policy.constantize
        else
          Policies::EarlyCareerPayments
        end
      end

      def nqt_in_academic_year_after_itt?
        !!nqt_in_academic_year_after_itt
      end

      def teaching_subject_now?
        !!teaching_subject_now
      end

      def induction_completed?
        !!induction_completed
      end

      def itt_subject_none_of_the_above?
        eligible_itt_subject == "none_of_the_above"
      end

      def employed_as_supply_teacher?
        !!employed_as_supply_teacher
      end

      def subject_to_formal_performance_action?
        !!subject_to_formal_performance_action
      end

      def subject_to_disciplinary_action?
        !!subject_to_disciplinary_action
      end

      def eligible_degree_subject?
        !!eligible_degree_subject
      end

      def current_school
        return nil if current_school_id.nil?

        @current_school ||= School.find_by(id: current_school_id)
      end
    end
  end
end
