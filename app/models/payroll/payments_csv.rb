require "csv"

module Payroll
  class PaymentsCsv
    attr_reader :payroll_run

    FIELDS_WITH_HEADERS = {
      title: "TITLE",
      first_name: "FORENAME",
      middle_name: "FORENAME2",
      surname: "SURNAME",
      national_insurance_number: "SS_NO",
      teacher_reference_number: "WORKS_REFERENCE",
      payroll_gender: "GENDER",
      marital_status: "MARITAL STATUS",
      start_date: "START_DATE",
      end_date: "END_DATE",
      date_of_birth: "BIRTH_DATE",
      email_address: "EMAIL",
      address_line_1: "ADDR_LINE_1",
      address_line_2: "ADDR_LINE_2",
      address_line_3: "ADDR_LINE_3",
      address_line_4: "ADDR_LINE_4",
      address_line_5: "ADDR_LINE_5",
      postcode: "POST CODE",
      country: "ADDRESS_COUNTRY",
      tax_code: "TAX_CODE",
      tax_basis: "TAX_BASIS",
      ni_category: "NI_CATEGORY",
      has_student_loan: "CON_STU_LOAN_I",
      student_loan_plan: "PLAN_TYPE",
      payment_method: "PAYMENT METHOD",
      payment_frequency: "PAYMENT FREQUENCY",
      banking_name: "BANK_NAME",
      bank_sort_code: "SORT_CODE",
      bank_account_number: "ACCOUNT_NUMBER",
      roll_number: "ROLL_NUMBER",
      scheme_amount: "SCHEME_AMOUNT",
      payment_id: "PAYMENT_ID",
      policies_in_payment: "CLAIM_POLICIES",
      right_to_work_confirm_status: "RIGHT TO WORK CONFIRM STATUS"
    }.freeze

    def initialize(payroll_run)
      @payroll_run = payroll_run
    end

    def file
      Tempfile.new.tap do |file|
        file.write(header_row)
        payroll_run.payments.includes(:claims).each do |payment|
          file.write(Payroll::PaymentCsvRow.new(payment).to_s)
        end
        file.rewind
      end
    end

    def filename
      "payroll_data_#{payroll_run.created_at.to_date.iso8601}.csv"
    end

    private

    def header_row
      CSV.generate_line(csv_headers)
    end

    def csv_headers
      FIELDS_WITH_HEADERS.values
    end
  end
end
