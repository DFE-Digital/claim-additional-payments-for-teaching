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
      roll_number: "ROLL_NUMBER",
      scheme_amount: "SCHEME_AMOUNT",
      payment_id: "PAYMENT_ID",
      policies_in_payment: "CLAIM_POLICIES",
      right_to_work_confirm_status: "RIGHT_TO_WORK_CONFIRM_STATUS"
    }.freeze

    def initialize(payroll_run)
      @payroll_run = payroll_run
    end

    def data
      buffer = ::StringIO.new
      Zip::OutputStream.write_buffer(buffer) do |file|
        payroll_run.payments_in_batches.each.with_index(1) do |batch, index|
          file = write_csv(file, batch, index)
        end
      end
      buffer.rewind
      buffer.read
    end

    def content_type
      "application/zip"
    end

    def filename
      "#{filename_base}.zip"
    end

    private

    def write_csv(file, batch, index)
      file.put_next_entry(filename_batch(index))
      file.write(header_row)
      batch.each do |payment|
        file.write(Payroll::PaymentCsvRow.new(payment).to_s)
      end
      file
    end

    def filename_batch(index)
      "#{filename_base}-batch_#{index}.csv"
    end

    def filename_base
      "payroll_data_#{payroll_run.created_at.to_date.iso8601}"
    end

    def header_row
      CSV.generate_line(csv_headers)
    end

    def csv_headers
      FIELDS_WITH_HEADERS.values
    end
  end
end
