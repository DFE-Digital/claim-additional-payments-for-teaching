class TeachersPensionsService < ApplicationRecord
  self.table_name = "teachers_pensions_service"

  scope :by_teacher_reference_number, ->(teacher_reference_number) { where(teacher_reference_number: teacher_reference_number) }
  scope :between_claim_dates, ->(start_date, end_date) { where(start_date: start_date..end_date) }
end
