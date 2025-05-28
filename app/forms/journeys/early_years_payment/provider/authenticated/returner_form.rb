module Journeys
  module EarlyYearsPayment
    module Provider
      module Authenticated
        class ReturnerForm < Form
          attribute :returning_within_6_months, :boolean

          validates :returning_within_6_months,
            inclusion: {in: [true, false], message: i18n_error_message(:inclusion)}

          def save
            return false if invalid?

            journey_session.answers.assign_attributes(returning_within_6_months:)

            reset_dependent_answers

            journey_session.save!
          end

          def start_date
            answers.start_date
          end

          def six_months_before_start_date
            start_date - 6.months
          end

          private

          def reset_dependent_answers
            if !journey_session.answers.returning_within_6_months
              journey_session.answers.assign_attributes(
                returner_worked_with_children: nil,
                returner_contract_type: nil
              )
            end
          end
        end
      end
    end
  end
end
