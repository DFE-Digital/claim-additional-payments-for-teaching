module Journeys
  module EarlyYearsTeachersFinancialIncentivePayments
    class CheckEligibilityForm < Form
      attribute :meets_eligibility_criteria, :boolean
      attribute :check_eligibility_answered, :boolean

      validates :meets_eligibility_criteria,
        inclusion: {
          in: [true, false],
          message: "Select yes or no to tell us if you meet the eligibility criteria"
        }

      def save
        return false if invalid?

        journey_session.answers.update!(
          check_eligibility_answered: true,
          fifty_percent_time_as_eyt: meets_eligibility_criteria,
          not_subject_to_performance_and_disciplinary: meets_eligibility_criteria
        )
      end

      def load_current_value(attribute)
        return super unless attribute == :meets_eligibility_criteria

        answers.fifty_percent_time_as_eyt
      end

      def completed?
        check_eligibility_answered
      end
    end
  end
end
