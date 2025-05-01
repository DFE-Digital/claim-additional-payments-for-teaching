module Journeys
  module TeacherStudentLoanReimbursement
    class SessionAnswers < Journeys::SessionAnswers
      attribute :qts_award_year, :string, pii: false
      attribute :provision_search, :string, pii: false
      attribute :possible_claim_school_id, :string, pii: false # UUID
      attribute :claim_school_id, :string, pii: false # UUID
      attribute :employment_status, :string, pii: false
      attribute :biology_taught, :boolean, pii: false
      attribute :chemistry_taught, :boolean, pii: false
      attribute :computing_taught, :boolean, pii: false
      attribute :languages_taught, :boolean, pii: false
      attribute :physics_taught, :boolean, pii: false
      attribute :taught_eligible_subjects, :boolean, pii: false
      attribute :student_loan_repayment_amount, :decimal, pii: false
      attribute :had_leadership_position, :boolean, pii: false
      attribute :mostly_performed_leadership_duties, :boolean, pii: false
      attribute :claim_school_somewhere_else, :boolean, pii: false
      attribute :student_loan_amount_seen, :boolean, pii: false

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

      def selected_claim_policy
        policy
      end

      def claim_school
        @claim_school ||= School.find_by(id: claim_school_id)
      end

      def claim_school_name
        claim_school&.name
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
    end
  end
end
