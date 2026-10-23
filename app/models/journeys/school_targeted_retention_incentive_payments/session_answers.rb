module Journeys
  module SchoolTargetedRetentionIncentivePayments
    class SessionAnswers < Journeys::SessionAnswers
      attribute :award_amount, :decimal, pii: false
      attribute :half_contracted_hours, :boolean, pii: false

      attribute :teacher_auth_teacher_reference_number, :string, pii: true
      attribute :teacher_auth_email, :string, pii: true
      attribute :teacher_auth_verified_name, :string, pii: true
      attribute :teacher_auth_verified_date_of_birth, :date, pii: true
      attribute :teacher_auth_one_login_uid, :string, pii: true
      attribute :teacher_auth_completed_at, :datetime, pii: false

      attribute :trs_data, pii: true
      attribute :trs_data_fetched_at, :datetime, pii: false

      attribute :national_insurance_number_correct, :boolean, pii: false
      attribute :national_insurance_number, :string, pii: true

      attribute :correct_details, :boolean, pii: false
      attribute :continue_claim, :boolean, pii: false
      attribute :claimant_declaration, :boolean, pii: false

      def policy
        Policies::TargetedRetentionIncentivePayments
      end

      def national_insurance_number_to_display
        if national_insurance_number_correct
          trs_data["nationalInsuranceNumber"]
        else
          national_insurance_number
        end
      end

      def dqt_record
        @dqt_record ||= Policies::TargetedRetentionIncentivePayments::StriDqtRecord.new(
          Dqt::Teacher.new(trs_data),
          self
        )
      end
    end
  end
end
