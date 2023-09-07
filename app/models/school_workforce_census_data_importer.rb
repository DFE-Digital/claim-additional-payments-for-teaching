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
        next if row[1].blank? || row[4] == "NULL" || row[1] == "NULL"

        row_to_school_workforce_census_hash(row)
      end.compact

      SchoolWorkforceCensus.insert_all(record_hashes) unless record_hashes.empty?

      batch += 1
    end
  end

  private

  def parse_csv_file(file)
    CSV.read(file.to_io, headers: false, encoding: "BOM|UTF-8")
  rescue CSV::MalformedCSVError
    errors.append("The selected file must be a CSV")
    nil
  end

  # NOTE: since there will be lots of rows, avoid instantiating model object
  def row_to_school_workforce_census_hash(row)
    now = Time.now.utc

    {
      school_urn: row[0],
      teacher_reference_number: row[1],
      contract_agreement_type: row[2],
      totfte: row[3],
      subject_description_sfr: row[4],
      general_subject_code: row[5],
      hours_taught: row[6],
      created_at: now,
      updated_at: now
    }
  end
end
