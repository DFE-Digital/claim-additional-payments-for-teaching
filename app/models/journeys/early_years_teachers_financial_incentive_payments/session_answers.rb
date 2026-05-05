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
    end
  end
end
