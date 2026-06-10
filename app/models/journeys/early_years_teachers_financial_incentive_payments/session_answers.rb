module Journeys
  module EarlyYearsTeachersFinancialIncentivePayments
    class SessionAnswers < Journeys::SessionAnswers
      attribute :teacher_auth_teacher_reference_number, :string, pii: true
      attribute :teacher_auth_email, :string, pii: true
      attribute :teacher_auth_verified_name, :string, pii: true
      attribute :teacher_auth_verified_date_of_birth, :date, pii: true
      attribute :teacher_auth_one_login_uid, :string, pii: true
      attribute :teacher_auth_completed_at, :datetime, pii: false

      attribute :nursery_search_query, :string, pii: false
      attribute :nursery_id, :string, pii: false
      attribute :teaching_qualification_confirmation, :boolean, pii: false

      attribute :check_eligibility_answered, :boolean, pii: false
      attribute :fifty_percent_time_as_eyt, :boolean, pii: false
      attribute :not_subject_to_performance_and_disciplinary, :boolean, pii: false
      attribute :confirmed_employment_proof_blob_ids, default: [], pii: true

      attribute :trs_data, pii: true
      attribute :trs_data_fetched_at, :datetime, pii: false
      attribute :has_eligible_qualification, :boolean, pii: false

      attribute :eligible_teaching_qualification_held_clicked, :boolean, pii: false
      attribute :continue_claim, :boolean, pii: false
      attribute :claimant_declaration, :boolean, pii: false

      def nursery
        @nursery ||= Policies::EarlyYearsTeachersFinancialIncentivePayments::EligibleEytfiProvider.find_by(
          id: nursery_id
        )
      end

      # required for student loan details updater
      def date_of_birth
        teacher_auth_verified_date_of_birth
      end

      def claim_already_submitted_this_policy_year?
        previous_claim.present?
      end

      def previous_claim
        @previous_claim ||= Claim
          .by_policy(Policies::EarlyYearsTeachersFinancialIncentivePayments)
          .current_academic_year
          .where.not(id: submitted_claim_id)
          .where.not(onelogin_uid: nil)
          .find_by(onelogin_uid: teacher_auth_one_login_uid)
      end
    end
  end
end
