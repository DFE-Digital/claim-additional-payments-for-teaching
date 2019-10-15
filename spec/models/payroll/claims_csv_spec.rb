require "rails_helper"

RSpec.describe Payroll::ClaimsCsv do
  subject(:claims_csv) { described_class.new(payroll_run) }

  let(:payroll_run) { create(:payroll_run, claims: [claim]) }
  let(:claim) { create(:claim, :submitted, address_line_1: "1 Test Road", address_line_2: "Test Town", postcode: "AB1 2CD") }

  describe "#file" do
    let(:file) { claims_csv.file }
    let(:file_lines) { file.read.split("\n") }

    it "returns a Tempfile" do
      expect(file).to be_a(Tempfile)
    end

    it "contains a headers row for the payroll file" do
      expected_header_row = %w[
        TITLE
        FORENAME
        FORENAME2
        SURNAME
        SS_NO
        GENDER
        START_DATE
        END_DATE
        BIRTH_DATE
        EMAIL
        ADDR_LINE_1
        ADDR_LINE_2
        ADDR_LINE_3
        ADDR_LINE_4
        ADDR_LINE_5
        ADDR_LINE_6
        ADDRESS_COUNTRY
        TAX_CODE
        TAX_BASIS
        NEW_EMP_Q_VL
        NI_CATEGORY
        CON_STU_LOAN_I
        PLAN_TYPE
        BANK_NAME
        SORT_CODE
        ACCOUNT_NUMBER
        ROLL_NUMBER
        SCHEME_NAME
        SCHEME_AMOUNT
        CLAIM_ID
      ].join(",")

      expect(file_lines[0]).to eq(expected_header_row)
    end

    it "contains data rows for passed in claims" do
      expected_claim_data_row = Payroll::ClaimCsvRow.new(claim).to_s.chomp

      expect(file_lines[1]).to eq(expected_claim_data_row)
    end
  end
end
