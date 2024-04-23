module Journeys
  module AdditionalPaymentsForTeaching
    class SupplyTeacherForm < Form
      attribute :employed_as_supply_teacher, :boolean

      validates :employed_as_supply_teacher, inclusion: {in: [true, false], message: i18n_error_message(:inclusion)}

      def save
        return false unless valid?

        update!(eligibility_attributes: attributes)
      end
    end
  end
end
