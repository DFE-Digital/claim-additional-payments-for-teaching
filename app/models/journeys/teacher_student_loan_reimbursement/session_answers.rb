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
      attribute :award_amount, :decimal, pii: false
      attribute :had_leadership_position, :boolean, pii: false
      attribute :mostly_performed_leadership_duties, :boolean, pii: false
      attribute :claim_school_somewhere_else, :boolean, pii: false
      attribute :student_loan_amount_seen, :boolean, pii: false

      attribute :teacher_auth_teacher_reference_number, :string, pii: true
      attribute :teacher_auth_email, :string, pii: true
      attribute :teacher_auth_verified_name, :string, pii: true
      attribute :teacher_auth_verified_date_of_birth, :date, pii: false
      attribute :teacher_auth_one_login_uid, :string, pii: true
      attribute :teacher_auth_completed_at, :datetime, pii: false
      attribute :trs_data_fetched_at, :datetime, pii: false
      attribute :teacher_auth_first_name, :string, pii: true
      attribute :teacher_auth_last_name, :string, pii: true
      attribute :teacher_auth_national_insurance_number, :string, pii: true
      attribute :teacher_auth_date_of_birth, :date, pii: true

      def dqt_teacher_record
        return unless dqt_teacher_status.present?

        @dqt_teacher_record ||= Policies::StudentLoans::DqtRecord.new(
          Dqt::Teacher.new(dqt_teacher_status)
        )
      end

      def has_dqt_data_for_claim?
        dqt_teacher_record.present? && dqt_teacher_record.qts_award_date.present?
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

      def has_tps_school_for_student_loan_in_previous_financial_year?
        tps_school_for_student_loan_in_previous_financial_year.present?
      end

      def tps_school_for_student_loan_in_previous_financial_year
        @tps_school_for_student_loan_in_previous_financial_year ||=
          TeachersPensionsService.tps_school_for_student_loan_in_previous_financial_year(
            teacher_reference_number: authenticated_trn
          )
      end

      def recent_tps_school
        @recent_tps_school ||= TeachersPensionsService.recent_tps_school(
          claim_date: session.created_at,
          teacher_reference_number: authenticated_trn
        )
      end

      def has_recent_tps_school?
        recent_tps_school.present?
      end

      def authenticated_trn
        if FeatureFlag.enabled?(:student_loans_teacher_auth)
          teacher_auth_teacher_reference_number
        else
          teacher_id_user_info["trn"]
        end
      end

      def authenticated_email_address
        if FeatureFlag.enabled?(:student_loans_teacher_auth)
          teacher_auth_email
        else
          teacher_id_user_info["email"]
        end
      end
    end
  end
end
