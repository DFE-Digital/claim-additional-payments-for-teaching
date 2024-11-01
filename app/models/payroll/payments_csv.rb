require "csv"

module Payroll
  class PaymentsCsv
    attr_reader :payroll_run

    ROW_SEPARATOR = "\r\n"

    FIELDS_WITH_HEADERS = {
      title: "TITLE",
      first_name: "FORENAME",
      middle_name: "FORENAME2",
      surname: "SURNAME",
      national_insurance_number: "SS_NO",
      payroll_gender: "GENDER",
      marital_status: "MARITAL_STATUS",
      start_date: "START_DATE",
      end_date: "END_DATE",
      date_of_birth: "BIRTH_DATE",
      email_address: "EMAIL",
      address_line_1: "ADDR_LINE_1",
      address_line_2: "ADDR_LINE_2",
      address_line_3: "ADDR_LINE_3",
      address_line_4: "ADDR_LINE_4",
      address_line_5: "ADDR_LINE_5",
      address_line_6: "ADDR_LINE_6",
      country: "ADDRESS_COUNTRY",
      tax_code: "TAX_CODE",
      tax_basis: "TAX_BASIS",
      ni_category: "NI_CATEGORY",
      has_student_loan: "CON_STU_LOAN_I",
      student_loan_plan: "PLAN_TYPE",
      payment_method: "PAYMENT_METHOD",
      payment_frequency: "PAYMENT_FREQUENCY",
      banking_name: "BANK_NAME",
      bank_sort_code: "SORT_CODE",
      bank_account_number: "ACCOUNT_NUMBER",
      scheme_amount: "SCHEME_AMOUNT",
      payment_id: "PAYMENT_ID",
      policies_in_payment: "CLAIM_POLICIES",
      right_to_work_confirm_status: "RIGHT_TO_WORK_CONFIRM_STATUS"
    }.freeze

    def initialize(payroll_run)
      @payroll_run = payroll_run
    end

    def data
      CSV.generate(
        row_sep: ROW_SEPARATOR,
        write_headers: true,
        headers: FIELDS_WITH_HEADERS.values
      ) do |csv|
        payroll_run.payments.includes(:claims).find_in_batches(batch_size: 1000) do |batch|
          batch.each do |payment|
            csv << PaymentCsvRow.new(payment).to_a
          end
        end
      end
    end

    def content_type
      "text/csv"
    end

    def filename
      "payroll_data_#{payroll_run.created_at.to_date.iso8601}.csv"
    end
  end
end
