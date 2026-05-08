module Journeys
  module EarlyYearsTeachersFinancialIncentivePayments
    class SessionAnswers < Journeys::SessionAnswers
      attribute :teacher_auth_teacher_reference_number, :string, pii: true
      attribute :teacher_auth_email, :string, pii: true
      attribute :teacher_auth_verified_name, :string, pii: true
      attribute :teacher_auth_verified_date_of_birth, :date, pii: true
      attribute :teacher_auth_one_login_uid, :string, pii: true

      attribute :nursery_search_query, :string, pii: false
      attribute :nursery_id, :string, pii: false
      attribute :teaching_qualification_confirmation, :boolean, pii: false

      def nursery
        @nursery ||= Policies::EarlyYearsTeachersFinancialIncentivePayments::EligibleEytfiProvider.find_by(
          id: nursery_id
        )
      end
    end
  end
end
