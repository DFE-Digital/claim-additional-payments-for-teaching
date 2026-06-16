module Journeys
  module EarlyYearsTeachersFinancialIncentivePayments
    class CheckEligibilityForm < Form
      attribute :fifty_percent_time_as_eyt, :boolean
      attribute :not_subject_to_performance_and_disciplinary, :boolean
      attribute :check_eligibility_answered, :boolean

      def save
        journey_session.answers.update!(
          check_eligibility_answered: true,
          fifty_percent_time_as_eyt:,
          not_subject_to_performance_and_disciplinary:
        )
      end

      def completed?
        check_eligibility_answered
      end
    end
  end
end
