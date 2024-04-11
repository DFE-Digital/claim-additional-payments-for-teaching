module Journeys
  module AdditionalPaymentsForTeaching
    class EmployedDirectlyForm < Form
      attribute :employed_directly, :boolean

      validates :employed_directly,
        inclusion: {
          in: [true, false],
          message: ->(object, _) { object.i18n_errors_path("select_employed_directly") }
        }

      def initialize(claim:, journey:, params:)
        super

        self.employed_directly = permitted_params.fetch(
          :employed_directly,
          claim.eligibility.employed_directly
        )
      end

      def save
        return false unless valid?

        update!({eligibility_attributes: {employed_directly:}})
      end
    end
  end
end
