module Journeys
  module EarlyYearsTeachers
    module Provider
      class EmployerPayeReferenceForm < Form
        attribute :employer_paye_reference, :string

        validates(
          :employer_paye_reference,
          presence: {message: "Enter the employer PAYE reference"}
        )

        def save
          return false if invalid?

          journey_session.answers.assign_attributes(
            employer_paye_reference: employer_paye_reference
          )
          journey_session.save!
        end
      end
    end
  end
end
