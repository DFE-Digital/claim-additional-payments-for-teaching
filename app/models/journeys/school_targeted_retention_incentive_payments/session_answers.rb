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

      attribute :trs_national_insurance_number, :string, pii: true
      attribute :trs_national_insurance_number_completed_at, :datetime, pii: false

      def policy
        Policies::TargetedRetentionIncentivePayments
      end
    end
  end
end
