module Journeys
  module AdditionalPaymentsForTeaching
    class InductionCompletedForm < Form
      attribute :induction_completed

      validates :induction_completed, presence: {message: i18n_error_message(:blank)}

      def save
        return false unless valid?

        journey_session.answers.assign_attributes(
          induction_completed: induction_completed
        )

        journey_session.save!
      end
    end
  end
end
