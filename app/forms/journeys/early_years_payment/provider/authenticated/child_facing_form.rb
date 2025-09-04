module Journeys
  module EarlyYearsPayment
    module Provider
      module Authenticated
        class ChildFacingForm < Form
          attribute :child_facing_confirmation_given, :boolean

          validates :child_facing_confirmation_given,
            inclusion: {
              in: [true, false],
              message: ->(form, data) { i18n_error_message(:inclusion, claimant_full_name: form.claimant_full_name).call(form, data) }
            }

          def save
            return false if invalid?

            journey_session.answers.assign_attributes(child_facing_confirmation_given:)
            journey_session.save!
          end

          def claimant_full_name
            journey_session.answers.full_name
          end
        end
      end
    end
  end
end
