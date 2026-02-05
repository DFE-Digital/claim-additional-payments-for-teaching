module Journeys
  module EarlyYearsTeachers
    module Practitioner
      class EmployerRefForm < Form
        attribute :employer_reference, :string

        validates :employer_reference,
          presence: {message: i18n_error_message(:blank)}

        def save
          return false unless valid?
          journey_session.answers.assign_attributes(employer_reference: employer_reference)
          journey_session.save!
        end
      end
    end
  end
end
