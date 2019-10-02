require "rails_helper"

RSpec.describe Payroll::ClaimsCsv do
  before do
    create(:claim, :submitted, address_line_1: "1 Test Road", address_line_2: "Test Town", postcode: "AB1 2CD")
  end

  subject { described_class.new(claims) }
  let(:claims) { Claim.all.order(:submitted_at) }
  let(:claim) { claims.first }
  let(:start_of_month) { Date.today.at_beginning_of_month }

  describe "file" do
    let(:file) { subject.file }
    let(:csv) { CSV.read(file) }
    let(:row) { Payroll::ClaimCsvRow.new(claim).to_s }

    it "returns the correct headers" do
      expect(csv[0]).to match_array([
        "TITLE",
        "FORENAME",
        "FORENAME2",
        "SURNAME",
        "SS_NO",
        "GENDER",
        "START_DATE",
        "END_DATE",
        "BIRTH_DATE",
        "EMAIL",
        "ADDR_LINE_1",
        "ADDR_LINE_2",
        "ADDR_LINE_3",
        "ADDR_LINE_4",
        "ADDR_LINE_5",
        "ADDR_LINE_6",
        "ADDRESS_COUNTRY",
        "TAX_CODE",
        "TAX_BASIS",
        "NEW_EMP_Q_VL",
        "NI_CATEGORY",
        "CON_STU_LOAN_I",
        "PLAN_TYPE",
        "BANK_NAME",
        "SORT_CODE",
        "ACCOUNT_NUMBER",
        "ROLL_NUMBER",
        "SCHEME_NAME",
        "SCHEME_AMOUNT",
        "CLAIM_ID",
      ])
    end

    it "returns the correct rows" do
      expect(csv.count).to eq(2)
      expect(csv[1]).to eq(CSV.parse_line(row))
    end
  end
end
