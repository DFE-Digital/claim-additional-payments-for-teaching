module Journeys
  module AdditionalPaymentsForTeaching
    class InductionCompletedForm < Form
      attribute :induction_completed

      validates :induction_completed, presence: {message: ->(object, _) { object.i18n_errors_path("select_yes_if_completed") }}

      def save
        return false unless valid?

        update!({eligibility_attributes: {induction_completed:}})
      end
    end
  end
end
