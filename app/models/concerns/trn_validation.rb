module TrnValidation
  extend ActiveSupport::Concern

  TRN_LENGTH = 7

  def normalize_teacher_reference_number(teacher_reference_number)
    teacher_reference_number.to_s.gsub(/\D/, "")
  end

  def valid_trn_length?(teacher_reference_number)
    teacher_reference_number.length <= TRN_LENGTH
  end
end
