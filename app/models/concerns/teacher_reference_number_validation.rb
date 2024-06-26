module TeacherReferenceNumberValidation
  extend ActiveSupport::Concern

  TRN_LENGTH = 7

  def validate_teacher_reference_number_length
    if teacher_reference_number.present? && !valid_teacher_reference_number_length?(teacher_reference_number)
      errors.add(:teacher_reference_number, "Teacher reference number must be #{TRN_LENGTH} digits")
    end
  end

  def normalise_teacher_reference_number
    self.teacher_reference_number = normalised_teacher_reference_number(teacher_reference_number)
  end

  def normalised_teacher_reference_number(trn)
    trn.to_s.gsub(/\D/, "")
  end

  def valid_teacher_reference_number_length?(trn)
    trn.to_s.length == TRN_LENGTH
  end

  # For some reason less than 7 digits is a thing for the school workforce census import!
  def valid_teacher_reference_number_length_for_school_workforce_census?(trn)
    trn.to_s.length <= TRN_LENGTH
  end
end
