module Journeys
  module EarlyYearsTeachers
    module Practitioner
      class ConfirmDetailsForm < Form
        attribute :details_correct, :boolean

        validates :details_correct,
          inclusion: {
            in: [true, false],
            message: i18n_error_message(:inclusion)
          }

        def save
          return false unless valid?

          if details_correct == false
            journey_session.answers.assign_attributes(
              first_name: nil,
              middle_name: nil,
              surname: nil,
              date_of_birth: nil,
              national_insurance_number: nil,
              teacher_reference_number: nil
            )
          end

          journey_session.answers.assign_attributes(
            details_correct: details_correct
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
