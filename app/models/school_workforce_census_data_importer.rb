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

  def initialize(file: nil, csv_string: nil)
    raise "either file or csv_string required not both" if file.present? && csv_string.present?

    @errors = []
    if file.present? || csv_string.present?
      @rows = parse_csv_file(file) if file.present?
      @rows = parse_csv_string(csv_string) if csv_string.present?
      check_headers
    else
      errors.append("Select a file")
    end
  end

  def run
    ActiveRecord::Base.transaction do
      SchoolWorkforceCensus.delete_all

      rows.each do |row|
        next if row.fetch("TRN").blank?

        school_workforce_census = row_to_school_workforce_census(row)
        school_workforce_census.save!
      end
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

  def parse_csv_string(csv_string)
    CSV.new(csv_string, headers: true).read
  rescue CSV::MalformedCSVError
    errors.append("The selected file must be a CSV")
    nil
  end

  def row_to_school_workforce_census(row)
    school_workforce_census = SchoolWorkforceCensus.new(teacher_reference_number: row.fetch("TRN"))
    school_workforce_census.subject_1 = row.fetch("GeneralSubjectDescription")
    school_workforce_census.subject_2 = row.fetch("2nd")
    school_workforce_census.subject_3 = row.fetch("3rd")
    school_workforce_census.subject_4 = row.fetch("4th")
    school_workforce_census.subject_5 = row.fetch("5th")
    school_workforce_census.subject_6 = row.fetch("6th")
    school_workforce_census.subject_7 = row.fetch("7th")
    school_workforce_census.subject_8 = row.fetch("8th")
    school_workforce_census.subject_9 = row.fetch("9th")
    school_workforce_census.subject_10 = row.fetch("10th")
    school_workforce_census.subject_11 = row.fetch("11th")
    school_workforce_census.subject_12 = row.fetch("12th")
    school_workforce_census.subject_13 = row.fetch("13th")
    school_workforce_census.subject_14 = row.fetch("14th")
    school_workforce_census.subject_15 = row.fetch("15th")
    school_workforce_census
  end
end
