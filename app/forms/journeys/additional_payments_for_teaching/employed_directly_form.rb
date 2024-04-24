module Journeys
  module AdditionalPaymentsForTeaching
    class EmployedDirectlyForm < Form
      attribute :employed_directly, :boolean

      validates :employed_directly, inclusion: {in: [true, false], message: i18n_error_message(:inclusion)}

      def save
        return false unless valid?

        update!(eligibility_attributes: attributes)
      end
    end
  end
end
