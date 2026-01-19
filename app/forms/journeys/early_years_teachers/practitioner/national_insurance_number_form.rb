module Journeys
  module EarlyYearsTeachers
    module Practitioner
      class NationalInsuranceNumberForm < Form
        attribute :national_insurance_number, :string

        validates :national_insurance_number, presence: {message: i18n_error_message(:presence)}

        def save
          return false if invalid?

          journey_session.answers.assign_attributes(
            national_insurance_number: national_insurance_number
          )
          journey_session.save!

          true
        end
      end
    end
  end
end
