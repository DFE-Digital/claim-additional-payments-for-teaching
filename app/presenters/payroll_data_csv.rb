require "csv"

class PayrollDataCsv
  attr_accessor :claims

  FIELDS = [
    :title,
    :first_name,
    :middle_name,
    :surname,
    :national_insurance_number,
    :payroll_gender,
    :start_date,
    :end_date,
    :date_of_birth,
    :email_address,
    :address_line_1,
    :address_line_2,
    :address_line_3,
    :address_line_4,
    :county,
    :postcode,
    :country,
    :tax_code,
    :tax_basis,
    :new_employee,
    :ni_category,
    :has_student_loan,
    :student_loan_plan,
    :bank_name,
    :bank_sort_code,
    :bank_account_number,
    :scheme_name,
    :scheme_amount,
    :reference,
  ].freeze

  def initialize(claims)
    self.claims = claims
  end

  def file
    Tempfile.new.tap do |file|
      file.write(header_row)
      claims.each do |claim|
        file.write(PayrollDataCsvRow.new(claim).to_s)
      end
      file.rewind
    end
  end

  private

  def header_row
    CSV.generate_line(csv_headers)
  end

  def csv_headers
    FIELDS.map { |h| header_string_for_field(h) }
  end

  def header_string_for_field(field)
    I18n.t("payroll_data_csv.#{field}.header")
  end
end
