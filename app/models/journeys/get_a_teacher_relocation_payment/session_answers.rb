module Journeys
  module GetATeacherRelocationPayment
    class SessionAnswers < Journeys::SessionAnswers
      attribute :application_route, :string
      attribute :state_funded_secondary_school, :boolean
      attribute :one_year, :boolean
      attribute :start_date, :date
      attribute :subject, :string
      attribute :visa_type, :string
      attribute :date_of_entry, :date
      attribute :nationality, :string
      attribute :passport_number, :string, pii: true
      attribute :school_headteacher_name, :string, pii: true

      def policy
        Policies::InternationalRelocationPayments
      end
    end
  end
end
