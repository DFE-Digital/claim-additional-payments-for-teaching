module Journeys
  module EarlyYearsTeachers
    module Practitioner
      class NationalInsuranceNumberForm < Form
        attribute :national_insurance_number, :string

        validates :national_insurance_number,
          presence: {message: i18n_error_message(:blank)}

        def save
          return false unless valid?
          journey_session.answers.assign_attributes(
            national_insurance_number: national_insurance_number
          )
          journey_session.save!
        end
      end
    end
  end
end
