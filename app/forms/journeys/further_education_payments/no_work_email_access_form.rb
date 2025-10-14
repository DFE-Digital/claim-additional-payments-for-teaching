module Journeys
  module FurtherEducationPayments
    class NoWorkEmailAccessForm < Form
      def save
        true
      end

      def redirect?
        true
      end

      def redirect_to
        "/further-education-payments/signed-out?reason=fe-no-work-email-access"
      end
    end
  end
end
