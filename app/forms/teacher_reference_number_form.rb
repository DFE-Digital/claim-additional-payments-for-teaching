class TeacherReferenceNumberForm < Form
  attribute :teacher_reference_number

  validates :teacher_reference_number,
    presence: {
      message: ->(form, _) { form.i18n_errors_path("blank") }
    }

  validates :teacher_reference_number,
    length: {
      is: 7,
      message: ->(form, _) { form.i18n_errors_path("length") }
    }, if: -> { teacher_reference_number.present? }

  def valid?(*)
    self.teacher_reference_number = teacher_reference_number&.gsub(/\D/, "")
    super
  end

  def save
    return false unless valid?

    update!(teacher_reference_number: teacher_reference_number)
  end
end
