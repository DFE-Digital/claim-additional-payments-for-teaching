module Journeys
  module EarlyYearsPayment
    module Provider
      module Authenticated
        class StartDateForm < Form
          include ActiveRecord::AttributeAssignment

          attribute :start_date, :date

          validates :start_date, presence: {message: i18n_error_message(:presence)}
          validates :start_date,
            comparison: {
              less_than: ->(_) {
                Date.tomorrow
              },
              message: i18n_error_message(:date_not_in_future)
            },
            if: :start_date
          validate :start_year_has_four_digits, if: :start_date

          def initialize(journey_session:, journey:, params:)
            super

            # Handle setting date from multi part params see
            # ActiveRecord::AttributeAssignment
            _assign_attributes(permitted_params)
          rescue ActiveRecord::MultiparameterAssignmentErrors
            # Invalid date was entered
            self.start_date = nil
          end

          def save
            return false unless valid?

            journey_session.answers.assign_attributes(start_date:)
            journey_session.save!
          end

          def nursery_name
            EligibleEyProvider.find_by(urn: answers.nursery_urn)&.nursery_name
          end

          private

          def start_year_has_four_digits
            if start_date.year < 1000
              errors.add(:start_date, i18n_errors_path(:year_must_have_4_digits))
            end
          end
        end
      end
    end
  end
end
