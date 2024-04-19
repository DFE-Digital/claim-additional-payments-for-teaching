module Journeys
  module AdditionalPaymentsForTeaching
    class EntireTermContractForm < Form
      attribute :has_entire_term_contract, :boolean

      validates :has_entire_term_contract,
        inclusion: {
          in: [true, false],
          message: ->(object, _) { object.i18n_errors_path("select_entire_term_contract") }
        }

      def save
        return false unless valid?

        update!({eligibility_attributes: {has_entire_term_contract:}})
      end
    end
  end
end
