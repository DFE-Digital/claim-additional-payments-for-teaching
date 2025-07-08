class DqtHigherEducationQualificationDataImporter < CsvImporter::Base
  include ::TeacherReferenceNumberValidation

  import_options(
    target_data_model: DqtHigherEducationQualification,
    append_only: true, # Note: the table is never purged
    transform_rows_with: :row_to_hash,
    skip_row_if: :skip_row_conditions?,
    mandatory_headers: [
      "trn",
      "date_of_birth",
      "nino",
      "subject_code",
      "description"
    ]
  )

  private

  def skip_row_conditions?(row)
    !valid_teacher_reference_number?(row[0]) ||
      !valid_date_of_birth?(row[1]) ||
      !valid_subject_code?(row[3])
  end

  def valid_teacher_reference_number?(trn)
    valid_teacher_reference_number_length?(trn)
  end

  def valid_date_of_birth?(dob)
    !!Date.parse(dob)
  rescue Date::Error
    false
  end

  def valid_subject_code?(subject_code)
    subject_code.present?
  end

  def row_to_hash(row)
    {
      teacher_reference_number: row[0],
      date_of_birth: Date.parse(row[1]).to_s,
      national_insurance_number: row[2],
      subject_code: row[3],
      description: row[4]
    }
  end
end
