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
      attribute :trs_national_insurance_number, :string, pii: true
      attribute :confirm_national_insurance_number, :boolean, pii: false

      attribute :hmrc_response_status, :integer, pii: false
      attribute :hmrc_response_body, :string, pii: true

      attribute :eligible_teaching_qualification_held_clicked, :boolean, pii: false
      attribute :continue_claim, :boolean, pii: false
      attribute :claimant_declaration, :boolean, pii: false

      def nursery
        Policies::EarlyYearsTeachersFinancialIncentivePayments::EligibleEytfiProvider.find_by(
          id: nursery_id
        )
      end

      def hmrc_response_received?
        hmrc_response_status.present? || hmrc_response_body.present?
      end

      def hmrc_employment_check_passed?
        return false unless nursery && hmrc_response_received?

        EmploymentCheck.new(
          setting: nursery,
          employments: employments_from_hmrc_response
        ).passed?
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

      def teacher_auth_verified_first_name
        teacher_auth_verified_name_parts.first
      end

      def teacher_auth_verified_last_name
        teacher_auth_verified_name_parts.last
      end

      private

      def teacher_auth_verified_name_parts
        return [] unless teacher_auth_verified_name.present?

        teacher_auth_verified_name.split(" ")
      end

      def employments_from_hmrc_response
        return [] unless hmrc_response_received?
        return [] unless hmrc_response_status == 200

        body = JSON.parse(hmrc_response_body.to_s)
        return [] unless body.is_a?(Hash) && body["employments"].is_a?(Array)

        employments = body.fetch("employments")
        return [] unless employments.all? do |employment|
          employment.is_a?(Hash) &&
            employment["employer"].is_a?(Hash) &&
            employment["employer"]["name"].is_a?(String) &&
            employment["employer"]["name"].present?
        end

        employments
      rescue JSON::ParserError
        []
      end
    end
  end
end
