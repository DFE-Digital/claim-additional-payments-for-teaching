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
            journey_session.save!
          end
        end
      end
    end
  end
end
