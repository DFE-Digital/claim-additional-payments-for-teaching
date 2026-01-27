module Journeys
  module EarlyYearsTeachers
    module Practitioner
      class TeacherReferenceNumberForm < Form
        attribute :teacher_reference_number, :string

        validates :teacher_reference_number,
          presence: {message: i18n_error_message(:blank)}

        def save
          return false unless valid?
          journey_session.answers.assign_attributes(
            teacher_reference_number: teacher_reference_number
          )
          journey_session.save!
        end
      end
    end
  end
end
