module Journeys
  module FurtherEducationPayments
    class ContractTypeForm < Form
      attribute :contract_type, :string

      validates :contract_type,
        inclusion: {
          in: ->(form) { form.radio_options.map(&:id) },
          message: ->(object, data) do
            i18n_error_message(:inclusion, school_name: object.school.name).call(object, data)
          end
        }

      def radio_options
        [
          Option.new(
            id: "permanent",
            name: t("options.permanent"),
            hint: "This includes full-time and part-time permanent contracts"
          ),
          Option.new(
            id: "fixed_term",
            name: t("options.fixed_term")
          ),
          Option.new(
            id: "variable_hours",
            name: t("options.variable_hours"),
            hint: "This includes zero hours contracts"
          ),
          Option.new(
            id: "employed_by_another_organisation",
            name: t("options.employed_by_another_organisation", school_name: school.name),
            hint: "For example, you are employed through a subsidiary, by an agency, as a contractor or by an organisation that is subcontracting with an eligible FE provider"
          )
        ]
      end

      def save
        return if invalid?

        journey_session.answers.assign_attributes(contract_type:)
        journey_session.save!
      end

      def school
        journey_session.answers.school
      end

      def clear_answers_from_session
        journey_session.answers.assign_attributes(contract_type: nil)
        journey_session.save!
      end
    end
  end
end
