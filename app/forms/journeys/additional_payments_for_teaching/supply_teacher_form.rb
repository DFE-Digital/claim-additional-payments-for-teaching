module Journeys
  module AdditionalPaymentsForTeaching
    class SupplyTeacherForm < Form
      attribute :employed_as_supply_teacher, :boolean

      validates :employed_as_supply_teacher,
        inclusion: {
          in: [true, false],
          message: ->(object, _) { object.i18n_errors_path("select_employed_as_supply_teacher") }
        }

      def initialize(claim:, journey:, params:)
        super

        self.employed_as_supply_teacher = permitted_params.fetch(
          :employed_as_supply_teacher,
          claim.eligibility.employed_as_supply_teacher
        )
      end

      def save
        return false unless valid?

        update!({eligibility_attributes: {employed_as_supply_teacher:}})
      end
    end
  end
end
