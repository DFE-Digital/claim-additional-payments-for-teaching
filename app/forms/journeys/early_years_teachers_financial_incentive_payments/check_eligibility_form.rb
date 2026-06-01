module Journeys
  module EarlyYearsTeachersFinancialIncentivePayments
    class CheckEligibilityForm < Form
      attribute :fifty_percent_time_as_eyt, :boolean
      attribute :not_subject_to_performance_and_disciplinary, :boolean

      def save
        journey_session.answers.update!(
          fifty_percent_time_as_eyt:,
          not_subject_to_performance_and_disciplinary:
        )
      end
    end
  end
end
