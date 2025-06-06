module Journeys
  module FurtherEducationPayments
    class TeacherReferenceNumberForm < Form
      include TeacherReferenceNumberValidation

      attribute :teacher_reference_number

      before_validation :normalise_teacher_reference_number

      # NOTE: teacher_reference_number is optional, however validate if supplied

      validates :teacher_reference_number,
        length: {
          is: TRN_LENGTH,
          message: ->(form, _) { form.i18n_errors_path("length") }
        }, if: -> { teacher_reference_number.present? }

      def save
        return false if invalid?

        journey_session.answers.assign_attributes(
          teacher_reference_number: teacher_reference_number
        )

        journey_session.save!
      end
    end
  end
end
