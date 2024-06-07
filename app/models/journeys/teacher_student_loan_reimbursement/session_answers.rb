module Journeys
  module TeacherStudentLoanReimbursement
    class SessionAnswers < Journeys::SessionAnswers
      attribute :qts_award_year, :string
      attribute :claim_school_id, :string # UUID
      attribute :employment_status, :string
      attribute :biology_taught, :boolean
      attribute :chemistry_taught, :boolean
      attribute :computing_taught, :boolean
      attribute :languages_taught, :boolean
      attribute :physics_taught, :boolean
      attribute :taught_eligible_subjects, :boolean
      attribute :student_loan_repayment_amount, :decimal
      attribute :had_leadership_position, :boolean
      attribute :mostly_performed_leadership_duties, :boolean
      attribute :claim_school_somewhere_else, :boolean

      def dqt_teacher_record
        return unless dqt_teacher_status.present?

        @dqt_teacher_record ||= Policies::StudentLoans::DqtRecord.new(
          Dqt::Teacher.new(dqt_teacher_status)
        )
      end

      def has_no_dqt_data_for_claim?
        dqt_teacher_status.blank? || dqt_teacher_record.has_no_data_for_claim?
      end

      def policy
        Policies::StudentLoans
      end

      def claim_school
        @claim_school ||= School.find_by(id: claim_school_id)
      end

      def claim_school_name
        claim_school&.name
      end

      def claim_school_somewhere_else?
        !!claim_school_somewhere_else
      end

      def subjects_taught
        [
          :biology_taught,
          :chemistry_taught,
          :physics_taught,
          :computing_taught,
          :languages_taught
        ].select { |subject| public_send(subject) }
      end

      def employed_at_no_school?
        employment_status.to_s == "no_school"
      end

      def employed_at_different_school?
        employment_status.to_s == "different_school"
      end

      def employed_at_claim_school?
        employment_status.to_s == "claim_school"
      end

      def employed_at_recent_tps_school?
        employment_status.to_s == "recent_tps_school"
      end

      def had_leadership_position?
        !!had_leadership_position
      end

      def mostly_performed_leadership_duties?
        !!mostly_performed_leadership_duties
      end
    end
  end
end
