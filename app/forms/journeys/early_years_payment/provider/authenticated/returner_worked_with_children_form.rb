module Journeys
  module EarlyYearsPayment
    module Provider
      module Authenticated
        class ReturnerWorkedWithChildrenForm < Form
          attribute :returner_worked_with_children, :boolean

          validates :returner_worked_with_children,
            inclusion: {in: [true, false], message: i18n_error_message(:inclusion)}

          def save
            return false if invalid?

            journey_session.answers.assign_attributes(returner_worked_with_children:)

            reset_dependent_answers

            journey_session.save!
          end

          private

          def reset_dependent_answers
            if !journey_session.answers.returner_worked_with_children
              journey_session.answers.assign_attributes(
                returner_contract_type: nil
              )

              session.fetch(:slugs, {}).delete("returner-contract-type")
            end
          end
        end
      end
    end
  end
end
