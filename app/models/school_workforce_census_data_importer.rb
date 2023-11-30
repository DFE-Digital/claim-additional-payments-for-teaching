class SchoolWorkforceCensusDataImporter < CsvImporter::Base
  include ::TrnValidation

  import_options(
    target_data_model: SchoolWorkforceCensus,
    transform_rows_with: :row_to_hash,
    skip_row_if: :skip_row_conditions?,
    parse_headers: false # Note: The CSV does not contain the header row
  )

  private

  def skip_row_conditions?(row)
    row[0].blank? || row[4] == "NULL" || row[0] == "NULL" || !valid_trn?(row[0])
  end

  def valid_trn?(trn)
    normalize_teacher_reference_number(trn)
    valid_trn_length?(trn)
  end

  def row_to_hash(row)
    {
      teacher_reference_number: row[0],
      school_urn: row[1],
      contract_agreement_type: row[2],
      totfte: row[3],
      subject_description_sfr: row[4],
      general_subject_code: row[5],
      hours_taught: row[6]
    }
  end
end
