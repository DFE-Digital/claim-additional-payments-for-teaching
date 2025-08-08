module Journeys
  module FurtherEducationPayments
    class CheckEligibilityIntroForm < Form
      def save
        # This is just an informational page with no data to save
        # The form just handles navigation to the next page
        true
      end
    end
  end
end
