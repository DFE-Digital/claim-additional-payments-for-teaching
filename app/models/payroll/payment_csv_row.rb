# frozen_string_literal: true

require "delegate"
require "csv"
require "excel_utils"

module Payroll
  class PaymentCsvRow < SimpleDelegator
    DATE_FORMAT = "%d/%m/%Y"
    UNITED_KINGDOM = "United Kingdom"
    BASIC_RATE_TAX_CODE = "BR"
    CUMULATIVE_TAX_BASIS = "0"
    NOT_EMPLOYEES_ONLY_JOB = "3"
    NI_CATEGORY_FOR_ALL_EMPLOYEES = "A"
    HAS_STUDENT_LOAN = "T"
    STUDENT_LOAN_PLAN_1 = "1"
    STUDENT_LOAN_PLAN_2 = "2"
    STUDENT_LOAN_PLAN_4 = "4"
    STUDENT_LOAN_PLAN_1_AND_3 = "1 and 3"
    STUDENT_LOAN_PLAN_2_AND_3 = "2 and 3"
    STUDENT_LOAN_PLAN_4_AND_3 = "4 and 3"
    STUDENT_LOAN_PLAN_3 = "3"

    def to_s
      CSV.generate_line(data)
    end

    private

    def data
      Payroll::PaymentsCsv::FIELDS_WITH_HEADERS.keys.map do |f|
        field = send(f)
        ExcelUtils.escape_formulas(field)
      end
    end

    def title
      "Prof"
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

    def address_line_1_components_size
      model.address_line_1.split.size
    end

    def address_line_1
      # Cantium - House or Flat Name and/or Number (optional)
      model.address_line_1 if address_line_1_components_size > 1
    end

    def address_line_2
      if address_line_1_components_size > 1
        model.address_line_2
      else
        [model.address_line_1, model.address_line_2].join(", ")
      end
    end

    def address_line_3
      # Cantium - Local Area (optional)
      nil
    end

    def address_line_4
      # Cantium - Town
      model.address_line_3
    end

    def address_line_5
      # Cantium - County
      # not returned from Ordnance Survey, we copy POST_TOWN to this field
      model.address_line_4.present? ? model.address_line_4 : model.address_line_3
    end

    def address_line_6
      # Cantium - PostCode
      model.postcode
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
      elsif model.student_loan_plan == "plan_4"
        STUDENT_LOAN_PLAN_4
      elsif model.student_loan_plan == "plan_1_and_3" || model.student_loan_plan == "plan_1_and_2_and_3"
        STUDENT_LOAN_PLAN_1_AND_3
      elsif model.student_loan_plan == "plan_2_and_3"
        STUDENT_LOAN_PLAN_2_AND_3
      elsif model.student_loan_plan == "plan_4_and_3"
        STUDENT_LOAN_PLAN_4_AND_3
      elsif model.student_loan_plan == "plan_3"
        STUDENT_LOAN_PLAN_3
      end
    end

    def banking_name
      model.banking_name
    end

    def bank_sort_code
      model.bank_sort_code.scan(/\d{2}/).join("-")
    end

    def scheme_amount
      model.award_amount.to_s
    end

    def roll_number
      model.building_society_roll_number
    end

    def payment_id
      model.id
    end

    def model
      __getobj__
    end
  end
end
