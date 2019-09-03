require "delegate"
require "csv"
require "excel_utils"

class PayrollDataCsvRow < SimpleDelegator
  DATE_FORMAT = "%m/%d/%Y".freeze

  def to_s
    CSV.generate_line(data)
  end

  private

  def data
    PayrollDataCsv::FIELDS.map do |f|
      field = send(f)
      ExcelUtils.escape_formulas(field)
    end
  end

  def title
  end

  def payroll_gender
    model.payroll_gender.chr.upcase
  end

  def start_date
    start_of_month.strftime(DATE_FORMAT)
  end

  def end_date
    (start_of_month + 7.days).strftime(DATE_FORMAT)
  end

  def start_of_month
    Date.today.at_beginning_of_month
  end

  def date_of_birth
    model.date_of_birth.strftime(DATE_FORMAT)
  end

  def county
  end

  def country
    I18n.t("payroll_data_csv.country.united_kingdom")
  end

  def tax_code
    I18n.t("payroll_data_csv.tax_code.basic_rate")
  end

  def tax_basis
    I18n.t("payroll_data_csv.tax_basis.cumulative")
  end

  def new_employee
    I18n.t("payroll_data_csv.new_employee.not_only_job")
  end

  def ni_category
    I18n.t("payroll_data_csv.ni_category.all_employees")
  end

  def has_student_loan
    model.has_student_loan ? I18n.t("payroll_data_csv.has_student_loan.true") : ""
  end

  def student_loan_plan
    I18n.t("payroll_data_csv.student_loan_plan.#{model.student_loan_plan}")
  end

  def bank_name
    model.full_name
  end

  def scheme_name
    I18n.t("payroll_data_csv.scheme_name.scheme_b")
  end

  def scheme_amount
    model.eligibility.student_loan_repayment_amount.to_s
  end

  def model
    __getobj__
  end
end
