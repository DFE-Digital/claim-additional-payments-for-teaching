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
      attribute :qualification, :string
      attribute :has_entire_term_contract, :boolean
      attribute :employed_directly, :boolean
      attribute :subject_to_disciplinary_action, :boolean
      attribute :subject_to_formal_performance_action, :boolean
      attribute :eligible_itt_subject, :string
      attribute :teaching_subject_now, :boolean
      attribute :itt_academic_year, AcademicYear::Type.new
      attribute :eligible_degree_subject, :boolean
      attribute :induction_completed, :boolean
      attribute :school_somewhere_else, :boolean

      def ecp_dqt_teacher_record
        return unless dqt_teacher_status.present?

        @ecp_dqt_teacher_record ||= Policies::EarlyCareerPayments::DqtRecord.new(
          Dqt::Teacher.new(dqt_teacher_status),
          self
        )
      end

      def lup_dqt_teacher_record
        return unless dqt_teacher_status.present?

        @lup_dqt_teacher_record ||= Policies::LevellingUpPremiumPayments::DqtRecord.new(
          Dqt::Teacher.new(dqt_teacher_status),
          self
        )
      end

      def has_no_dqt_data_for_claim?
        dqt_teacher_status.blank? || \
          lup_dqt_teacher_record.has_no_data_for_claim? || \
          ecp_dqt_teacher_record.has_no_data_for_claim?
      end
    end
  end
end
