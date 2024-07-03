module Journeys
  module FurtherEducationPayments
    class ContractTypeForm < Form
      attribute :contract_type, :string

      validates :contract_type,
        inclusion: {in: ->(form) { form.radio_options.map(&:id) }, message: i18n_error_message(:inclusion)}

      def radio_options
        [
          OpenStruct.new(
            id: "permanent",
            name: "Permanent contract",
            hint: "This includes full-time and part-time contracts"
          ),
          OpenStruct.new(
            id: "fixed-term",
            name: "Fixed-term contract"
          ),
          OpenStruct.new(
            id: "variable-hours",
            name: "Variable hours contract",
            hint: "This includes zero hours contract and hourly paid"
          )
        ]
      end

      def save
        return if invalid?

        journey_session.answers.assign_attributes(contract_type:)
        journey_session.save!
      end
    end
  end
end
