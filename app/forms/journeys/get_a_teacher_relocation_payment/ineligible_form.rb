module Journeys
  module GetATeacherRelocationPayment
    class IneligibleForm < Form
      def save
        true
      end
    end
  end
end
