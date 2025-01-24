module Journeys
  module FurtherEducationPayments
    class ContractTypeForm < Form
      attribute :contract_type, :string

      validates :contract_type,
        inclusion: {
          in: ->(form) { form.radio_options.map(&:id) },
          message: ->(object, data) { i18n_error_message(:inclusion, school_name: object.school.name).call(object, data) }
        }

      def radio_options
        [
          OpenStruct.new(
            id: "permanent",
            name: t("options.permanent"),
            hint: "This includes full-time and part-time contracts"
          ),
          OpenStruct.new(
            id: "fixed_term",
            name: t("options.fixed_term")
          ),
          OpenStruct.new(
            id: "variable_hours",
            name: t("options.variable_hours"),
            hint: "This includes zero hours contracts"
          )
        ]
      end

      def save
        return if invalid?

        reset_dependent_answers

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

      private

      def reset_dependent_answers
        if changing_answer? && old_answer == "fixed_term"
          journey_session.answers.assign_attributes(
            fixed_term_full_year: nil,
            taught_at_least_one_term: nil
          )
        end

        if changing_answer? && old_answer == "variable_hours"
          journey_session.answers.assign_attributes(
            taught_at_least_one_term: nil
          )
        end
      end

      def changing_answer?
        journey_session.answers.contract_type.present? && (contract_type != journey_session.answers.contract_type)
      end

      def old_answer
        journey_session.answers.contract_type
      end
    end
  end
end
