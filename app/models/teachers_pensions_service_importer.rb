require "file_download"
require "csv"

class TeachersPensionsServiceImporter
  attr_reader :errors, :rows

  EXPECTED_HEADERS = [
    "Teacher reference number",
    "NINO",
    "Start Date",
    "End Date",
    "Employer ID",
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
    batch = 1
    rows.each_slice(2000) do |batch_rows|
      Rails.logger.info "Processing TPS upload batch #{batch}"

      record_hashes = batch_rows.map do |row|
        next if row.fetch("Teacher reference number").blank?

        row_to_tps_hash(row)
      end.compact

      TeachersPensionsService.insert_all(record_hashes) unless record_hashes.empty?

      batch += 1
    end
  end

  private

  # NOTE: since there will be lots of rows, avoid instantiating model object
  def row_to_tps_hash(row)
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
