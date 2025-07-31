module Journeys
  module FurtherEducationPayments
    class IdentityVerificationForm < Form
      def save
        true
      end

      def completed?
        journey_session.answers.onelogin_idv_at.present?
      end
    end
  end
end
