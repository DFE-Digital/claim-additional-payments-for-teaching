module Journeys
  module EarlyYearsTeachers
    module Practitioner
      class EligibilityConfirmedForm < Form
        attribute :accept_payment, :boolean

        validates :accept_payment,
          inclusion: {
            in: [true, false],
            message: i18n_error_message(:inclusion)
          }

        def save
          return false unless valid?

          journey_session.answers.assign_attributes(
            accept_payment: accept_payment
          )
          journey_session.save!
        end

        def radio_options
          [
            OpenStruct.new(id: true, name: "Yes"),
            OpenStruct.new(id: false, name: "No")
          ]
        end
      end
    end
  end
end
