module Journeys
  module EarlyYearsPayment
    module Provider
      module Authenticated
        class ChildFacingForm < Form
          attribute :child_facing_confirmation_given, :boolean

          validates :child_facing_confirmation_given,
            presence: {message: i18n_error_message(:presence)}

          def save
            return false if invalid?

            journey_session.answers.assign_attributes(child_facing_confirmation_given:)
            journey_session.save!
          end
        end
      end
    end
  end
end
