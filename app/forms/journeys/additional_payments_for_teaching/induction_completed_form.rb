module Journeys
  module AdditionalPaymentsForTeaching
    class InductionCompletedForm < Form
      attribute :induction_completed

      validates :induction_completed, presence: {message: ->(object, _) { object.i18n_errors_path("select_yes_if_completed") }}

      def initialize(claim:, journey:, params:)
        super

        self.induction_completed = permitted_params.fetch(:induction_completed, claim.eligibility.induction_completed)
      end

      def save
        return false unless valid?

        update!({eligibility_attributes: {induction_completed:}})
      end
    end
  end
end
