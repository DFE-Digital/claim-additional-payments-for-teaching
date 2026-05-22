module Journeys
  module EarlyYearsTeachersFinancialIncentivePayments
    class SignInForm < Form
      def save
        true
      end

      def completed?
        journey_session.answers.teacher_auth_completed_at
      end
    end
  end
end
