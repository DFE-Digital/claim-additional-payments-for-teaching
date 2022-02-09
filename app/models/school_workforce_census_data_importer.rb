require "file_download"
require "csv"

class SchoolWorkforceCensusDataImporter
  attr_reader :errors, :rows

  EXPECTED_HEADERS = [
    "TRN",
    "GeneralSubjectDescription, 1st occurance",
    "2nd",
    "3rd",
    "4th",
    "5th",
    "6th",
    "7th",
    "8th",
    "9th"
  ].freeze

  def initialize(file)
    @errors = []
    @rows = parse_csv(file)
    check_headers
  end

  def run
    rows.each do |row|
      school_workforce_census = row_to_school_workforce_census(row)
      school_workforce_census.save!
    end
  end

  private

  def check_headers
    if rows
      missing_headers = EXPECTED_HEADERS - rows.headers
      errors.append("The selected file is missing some expected columns: #{missing_headers.join(", ")}") if missing_headers.any?
    end
  end

  def parse_csv(file)
    if file.nil?
      errors.append("Select a file")
      nil
    else
      CSV.read(file.to_io, headers: true, encoding: "BOM|UTF-8")
    end
  rescue CSV::MalformedCSVError
    errors.append("The selected file must be a CSV")
    nil
  end

  def row_to_school_workforce_census(row)
    school_workforce_census = SchoolWorkforceCensus.find_or_initialize_by(teacher_reference_number: row.fetch("TRN"))
    school_workforce_census.subject_1 = row.fetch("GeneralSubjectDescription, 1st occurance")
    school_workforce_census.subject_2 = row.fetch("2nd")
    school_workforce_census.subject_3 = row.fetch("3rd")
    school_workforce_census.subject_4 = row.fetch("4th")
    school_workforce_census.subject_5 = row.fetch("5th")
    school_workforce_census.subject_6 = row.fetch("6th")
    school_workforce_census.subject_7 = row.fetch("7th")
    school_workforce_census.subject_8 = row.fetch("8th")
    school_workforce_census.subject_9 = row.fetch("9th")
    school_workforce_census
  end
end
