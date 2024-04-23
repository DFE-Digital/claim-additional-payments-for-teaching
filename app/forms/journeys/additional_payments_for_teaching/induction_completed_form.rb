module Journeys
  module AdditionalPaymentsForTeaching
    class InductionCompletedForm < Form
      attribute :induction_completed

      validates :induction_completed, presence: {message: i18n_error_message(:blank)}

      def save
        return false unless valid?

        update!(eligibility_attributes: attributes)
      end
    end
  end
end
