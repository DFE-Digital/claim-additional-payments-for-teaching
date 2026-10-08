module Journeys
  module EarlyYearsTeachersFinancialIncentivePayments
    class CheckEligibilityForm < Form
      attribute :meets_teaching_standards, :boolean
      attribute :check_eligibility_answered, :boolean

      validates :meets_teaching_standards,
        inclusion: {
          in: [true, false],
          message: "Select yes or no to tell us if you meet the eligibility criteria"
        }

      def save
        return false if invalid?

        journey_session.answers.update!(
          check_eligibility_answered: true,
          fifty_percent_time_as_eyt: meets_teaching_standards,
          not_subject_to_performance_and_disciplinary: meets_teaching_standards
        )
      end

      def load_current_value(attribute)
        return super unless attribute == :meets_teaching_standards

        answers.fifty_percent_time_as_eyt
      end

      def completed?
        check_eligibility_answered
      end
    end
  end
end
