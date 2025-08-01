module Journeys
  module FurtherEducationPayments
    class SignInForm < Form
      def save
        true
      end

      def completed?
        journey_session.answers.onelogin_uid
      end
    end
  end
end
