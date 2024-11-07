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
    NI_CATEGORY_FOR_ALL_EMPLOYEES = "A"
    HAS_STUDENT_LOAN = "T"
    MARITAL_STATUS = "Other"
    PAYMENT_FREQUENCY = "Weekly"
    PAYMENT_METHOD = "Direct BACS"
    RIGHT_TO_WORK_CONFIRM_STATUS = "2"
    TITLE = "Prof."

    def to_a
      Payroll::PaymentsCsv::FIELDS_WITH_HEADERS.keys.map do |f|
        field = send(f)
        ExcelUtils.escape_formulas(field)
      end
    end

    private

    def title
      TITLE
    end

    def payroll_gender
      model.payroll_gender.chr.upcase
    end

    def start_date
      Date.today.at_beginning_of_month.strftime(DATE_FORMAT)
    end

    def end_date
      Date.today.at_end_of_month.strftime(DATE_FORMAT)
    end

    def date_of_birth
      model.date_of_birth.strftime(DATE_FORMAT)
    end

    def address_line_1_components_size
      model.address_line_1.split.size
    end

    def address_line_1
      # Payroll - House or Flat Name and/or Number (optional)
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
      # Payroll - Local Area (optional)
      nil
    end

    def address_line_4
      # Payroll - Town
      model.address_line_3
    end

    def address_line_5
      # Payroll - County
      # not returned from Ordnance Survey, we copy POST_TOWN to this field
      model.address_line_4.present? ? model.address_line_4 : model.address_line_3
    end

    def address_line_6
      # Payroll - PostCode
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

    def ni_category
      NI_CATEGORY_FOR_ALL_EMPLOYEES
    end

    def has_student_loan
      HAS_STUDENT_LOAN if model.has_student_loan
    end

    def student_loan_plan
      return if model.student_loan_plan.blank?

      model.student_loan_plan.gsub("plan", "").humanize
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

    # NOTE: Payroll people require this on the CSV, but we no longer ask or store it
    def roll_number
      nil
    end

    def payment_id
      model.id
    end

    def marital_status
      MARITAL_STATUS
    end

    def payment_method
      PAYMENT_METHOD
    end

    def payment_frequency
      PAYMENT_FREQUENCY
    end

    def right_to_work_confirm_status
      RIGHT_TO_WORK_CONFIRM_STATUS
    end

    def model
      __getobj__
    end
  end
end
