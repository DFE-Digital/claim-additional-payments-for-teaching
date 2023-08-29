require "file_download"
require "csv"

class SchoolWorkforceCensusDataImporter
  attr_reader :errors, :rows

  EXPECTED_HEADERS = [
    "TRN",
    "URN",
    "ContractAgreementType",
    "TotalFTE",
    "SubjectDescription_SFR",
    "GeneralSubjectCode",
    "hours_taught"
  ].freeze

  def initialize(file)
    @errors = []
    if file.present?
      @rows = parse_csv_file(file)
      check_headers
    else
      errors.append("Select a file")
    end
  end

  def run
    SchoolWorkforceCensus.delete_all

    batch = 1
    rows.each_slice(500) do |batch_rows|
      Rails.logger.info "Processing batch #{batch}"

      record_hashes = batch_rows.map do |row|
        next if row.fetch("TRN").blank? || row.fetch("SubjectDescription_SFR") == "NULL"

        row_to_school_workforce_census_hash(row)
      end.compact

      SchoolWorkforceCensus.insert_all(record_hashes) unless record_hashes.empty?

      batch += 1
    end
  end

  private

  def check_headers
    if rows
      missing_headers = EXPECTED_HEADERS - rows.headers
      errors.append("The selected file is missing some expected columns: #{missing_headers.join(", ")}") if missing_headers.any?
    end
  end

  def parse_csv_file(file)
    CSV.read(file.to_io, headers: true, encoding: "BOM|UTF-8")
  rescue CSV::MalformedCSVError
    errors.append("The selected file must be a CSV")
    nil
  end

  # NOTE: since there will be lots of rows, avoid instantiating model object
  def row_to_school_workforce_census_hash(row)
    now = Time.now.utc

    {
      teacher_reference_number: row.fetch("TRN"),
      urn: row.fetch("URN"),
      contract_agreement_type: row.fetch("ContractAgreementType"),
      totfte: row.fetch("TotalFTE"),
      subject_description_sfr: row.fetch("SubjectDescription_SFR"),
      general_subject_code: row.fetch("GeneralSubjectCode"),
      hours_taught: row.fetch("hours_taught"),
      created_at: now,
      updated_at: now
    }
  end
end
