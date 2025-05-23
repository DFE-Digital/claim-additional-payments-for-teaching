module Journeys
  module GetATeacherRelocationPayment
    class SessionAnswers < Journeys::SessionAnswers
      attribute :application_route, :string, pii: false
      attribute :state_funded_secondary_school, :boolean, pii: false
      attribute :one_year, :boolean, pii: false
      attribute :start_date, :date, pii: false
      attribute :subject, :string, pii: false
      attribute :visa_type, :string, pii: false
      attribute :date_of_entry, :date, pii: false
      attribute :nationality, :string, pii: false
      attribute :passport_number, :string, pii: true
      attribute :school_headteacher_name, :string, pii: true
      attribute :changed_workplace_or_new_contract, :boolean, pii: false

      def policy
        Policies::InternationalRelocationPayments
      end
    end
  end
end
