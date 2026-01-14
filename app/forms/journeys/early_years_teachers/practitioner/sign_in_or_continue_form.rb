module Journeys
  module EarlyYearsTeachers
    module Practitioner
      class SignInOrContinueForm < Form
        attribute :tid_sign_in, :boolean

        validates(
          :tid_sign_in,
          inclusion: {
            in: [true, false],
            message: "You must select an option"
          }
        )

        def save
          return false unless valid?

          journey_session.answers.assign_attributes(tid_sign_in: tid_sign_in)

          if tid_sign_in
            journey_session.answers.assign_attributes(
              first_name: "Edna",
              surname: "Krabappel",
              date_of_birth: Date.new(1970, 1, 1),
              national_insurance_number: "AB123456C",
              teacher_reference_number: "1234567"
            )
          end

          journey_session.save!
        end
      end
    end
  end
end
