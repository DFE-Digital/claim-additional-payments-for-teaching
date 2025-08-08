module Journeys
  module FurtherEducationPayments
    class NoWorkEmailAccessForm < Form
      def save
        true
      end

      def after_render
        session.destroy
      end
    end
  end
end
