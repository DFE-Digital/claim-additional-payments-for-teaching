# frozen_string_literal: true

require "delegate"
require "csv"
require "excel_utils"

module Payroll
  class ClaimCsvRow < SimpleDelegator
    DATE_FORMAT = "%Y%m%d"
    UNITED_KINGDOM = "United Kingdom"
    BASIC_RATE_TAX_CODE = "BR"
    CUMULATIVE_TAX_BASIS = "0"
    NOT_EMPLOYEES_ONLY_JOB = "3"
    NI_CATEGORY_FOR_ALL_EMPLOYEES = "A"
    HAS_STUDENT_LOAN = "T"
    STUDENT_LOAN_PLAN_1 = "1"
    STUDENT_LOAN_PLAN_2 = "2"

    def to_s
      CSV.generate_line(data)
    end

    private

    def data
      Payroll::ClaimsCsv::FIELDS_WITH_HEADERS.keys.map do |f|
        field = send(f)
        ExcelUtils.escape_formulas(field)
      end
    end

    def title
      # Hardcoded as HMRC require it, but we don't collect it. As HMRC will already hold
      # a record for teachers, they will be able to match to their existing record based
      # on other fields such as name, dob, NI number
      "Captain"
    end

    def payroll_gender
      model.payroll_gender.chr.upcase
    end

    def start_date
      second_monday_of_month.strftime(DATE_FORMAT)
    end

    def end_date
      second_monday_of_month.end_of_week.strftime(DATE_FORMAT)
    end

    def second_monday_of_month
      day = Date.today.at_beginning_of_month
      day += 1.days until day.monday?
      day.next_week
    end

    def date_of_birth
      model.date_of_birth.strftime(DATE_FORMAT)
    end

    def address_lines
      @address_lines ||= [
        model.address_line_1,
        model.address_line_2,
        model.address_line_3,
        model.address_line_4,
        model.postcode,
      ].compact
    end

    def address_line_1
      address_lines[0]
    end

    def address_line_2
      address_lines[1]
    end

    def address_line_3
      address_lines[2]
    end

    def address_line_4
      address_lines[3]
    end

    def address_line_5
      address_lines[4]
    end

    def address_line_6
    end

    def country
      UNITED_KINGDOM
    end

    def tax_code
      BASIC_RATE_TAX_CODE
    end

    def tax_basis
      CUMULATIVE_TAX_BASIS
    end

    def new_employee
      NOT_EMPLOYEES_ONLY_JOB
    end

    def ni_category
      NI_CATEGORY_FOR_ALL_EMPLOYEES
    end

    def has_student_loan
      HAS_STUDENT_LOAN if model.has_student_loan
    end

    def student_loan_plan
      if model.student_loan_plan == "plan_1" || model.student_loan_plan == "plan_1_and_2"
        STUDENT_LOAN_PLAN_1
      elsif model.student_loan_plan == "plan_2"
        STUDENT_LOAN_PLAN_2
      end
    end

    def banking_name
      model.banking_name
    end

    def scheme_name
      model.policy.name.titlecase
    end

    def scheme_amount
      model.eligibility.student_loan_repayment_amount.to_s
    end

    def roll_number
      model.building_society_roll_number
    end

    def model
      __getobj__
    end
  end
end
