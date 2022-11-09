require "file_download"
require "csv"

class SchoolWorkforceCensusDataImporter
  attr_reader :errors, :rows

  EXPECTED_HEADERS = [
    "TRN",
    "GeneralSubjectDescription",
    "2nd",
    "3rd",
    "4th",
    "5th",
    "6th",
    "7th",
    "8th",
    "9th",
    "10th",
    "11th",
    "12th",
    "13th",
    "14th",
    "15th"
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
        next if row.fetch("TRN").blank?

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
      subject_1: row.fetch("GeneralSubjectDescription"),
      subject_2: row.fetch("2nd"),
      subject_3: row.fetch("3rd"),
      subject_4: row.fetch("4th"),
      subject_5: row.fetch("5th"),
      subject_6: row.fetch("6th"),
      subject_7: row.fetch("7th"),
      subject_8: row.fetch("8th"),
      subject_9: row.fetch("9th"),
      subject_10: row.fetch("10th"),
      subject_11: row.fetch("11th"),
      subject_12: row.fetch("12th"),
      subject_13: row.fetch("13th"),
      subject_14: row.fetch("14th"),
      subject_15: row.fetch("15th"),
      created_at: now,
      updated_at: now
    }
  end
end
