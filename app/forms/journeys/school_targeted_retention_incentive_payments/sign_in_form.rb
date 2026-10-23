module Journeys
  module SchoolTargetedRetentionIncentivePayments
    class SignInForm < Form
      def save
        true
      end

      def completed?
        journey_session.answers.teacher_auth_one_login_uid
      end
    end
  end
end
