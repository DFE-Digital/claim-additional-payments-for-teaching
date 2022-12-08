require "file_download"
require "csv"

class TeachersPensionsServiceImporter
  attr_reader :errors, :rows

  EXPECTED_HEADERS = [
    "Teacher reference number",
    "NINO",
    "Start Date",
    "End Date",
    "Annual salary",
    "Monthly pay",
    "N/A",
    "LA URN",
    "School URN"
  ].freeze

  def initialize(file)
    @errors = []
    @rows = parse_csv(file)
    check_headers
  end

  # NOTE: Duplicate trn with same start_dates are skipped
  def run
    ActiveRecord::Base.transaction do
      rows.each do |row|
        tps_data = row_to_tps(row)
        tps_data.save! if tps_data.valid?
      end
    end
  end

  private

  def check_headers
    return unless rows

    missing_headers = EXPECTED_HEADERS - rows.headers
    errors.append("The selected file is missing some expected columns: #{missing_headers.join(", ")}") if missing_headers.any?
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

  def row_to_tps(row)
    trn_val = row.fetch("Teacher reference number")

    tps_data = TeachersPensionsService.new(teacher_reference_number: trn_without_gender_digit(trn_val))
    tps_data.start_date = row.fetch("Start Date")
    tps_data.end_date = row.fetch("End Date")
    tps_data.la_urn = row.fetch("LA URN")
    tps_data.school_urn = row.fetch("School URN")
    tps_data.gender_digit = gender_digit(trn_val)
    tps_data
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
