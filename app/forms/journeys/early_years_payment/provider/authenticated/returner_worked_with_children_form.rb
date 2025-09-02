module Journeys
  module EarlyYearsPayment
    module Provider
      module Authenticated
        class ReturnerWorkedWithChildrenForm < Form
          attribute :returner_worked_with_children, :boolean

          validates :returner_worked_with_children,
            inclusion: {
              in: [true, false],
              message: ->(form, data) {
                i18n_error_message(
                  :inclusion,
                  claimant_full_name: form.claimant_full_name
                ).call(form, data)
              }
            }

          def save
            return false if invalid?

            journey_session.answers.assign_attributes(returner_worked_with_children:)

            reset_dependent_answers

            journey_session.save!
          end

          def claimant_full_name
            journey_session.answers.full_name
          end

          private

          def reset_dependent_answers
            if !journey_session.answers.returner_worked_with_children
              journey_session.answers.assign_attributes(
                returner_contract_type: nil
              )
            end
          end
        end
      end
    end
  end
end
