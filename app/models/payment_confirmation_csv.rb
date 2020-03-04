require "csv"

class PaymentConfirmationCsv
  attr_reader :rows, :errors

  EXPECTED_HEADERS = [
    "Payroll Reference",
    "Gross Value",
    "Payment ID",
    "NI",
    "Employers NI",
    "Student Loans",
    "Tax",
    "Net Pay"
  ].freeze

  def initialize(file)
    @errors = []
    @rows = parse_csv(file)
    check_headers
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
end
