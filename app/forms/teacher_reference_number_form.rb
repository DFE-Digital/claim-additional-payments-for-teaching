class TeacherReferenceNumberForm < Form
  attribute :teacher_reference_number

  before_validation do
    self.teacher_reference_number = teacher_reference_number&.gsub(/\D/, "")
  end

  validates :teacher_reference_number,
    presence: {
      message: ->(form, _) { form.i18n_errors_path("blank") }
    }

  validates :teacher_reference_number,
    length: {
      is: 7,
      message: ->(form, _) { form.i18n_errors_path("length") }
    }, if: -> { teacher_reference_number.present? }

  def save
    return false unless valid?

    journey_session.answers.assign_attributes(
      teacher_reference_number: teacher_reference_number
    )

    journey_session.save!
  end
end
