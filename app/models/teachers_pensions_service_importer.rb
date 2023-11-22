class TeachersPensionsServiceImporter < CsvImporter::Base
  import_options(
    target_data_model: TeachersPensionsService,
    append_only: true, # Note: the table is never purged
    batch_size: 2000,
    transform_rows_with: :row_to_hash,
    skip_row_if: :skip_row_conditions?,
    mandatory_headers: [
      "Teacher reference number",
      "NINO",
      "Start Date",
      "End Date",
      "Employer ID",
      "LA URN",
      "School URN"
    ]
  )

  private

  def skip_row_conditions?(row)
    row.fetch("Teacher reference number").blank?
  end

  def row_to_hash(row)
    now = Time.now.utc
    trn = row.fetch("Teacher reference number")

    {
      teacher_reference_number: trn_without_gender_digit(trn),
      start_date: row.fetch("Start Date"),
      end_date: row.fetch("End Date"),
      employer_id: row.fetch("Employer ID"),
      la_urn: row.fetch("LA URN"),
      school_urn: row.fetch("School URN"),
      nino: row.fetch("NINO"),
      gender_digit: gender_digit(trn),
      created_at: now,
      updated_at: now
    }
  end

  # First 7 digits
  def trn_without_gender_digit(trn_str)
    trn_str&.strip&.slice(0, 7)
  end

  # 8th digit if there is one
  # nil = only 7 digit trn provided
  # 1 = male
  # 2 = female
  def gender_digit(trn_str)
    trn_str&.strip&.[](7)
  end
end
