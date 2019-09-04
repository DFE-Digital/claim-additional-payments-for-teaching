require "rails_helper"

RSpec.describe Payroll::ClaimsCsv do
  before do
    create(:claim, :submitted)
  end

  subject { described_class.new(claims) }
  let(:claims) { Claim.all.order(:submitted_at) }
  let(:claim) { claims.first }
  let(:start_of_month) { Date.today.at_beginning_of_month }

  describe "file" do
    let(:file) { subject.file }
    let(:csv) { CSV.read(file) }

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
        "SCHEME_NAME",
        "SCHEME_AMOUNT",
        "CLAIM_ID",
      ])
    end

    it "returns the correct rows" do
      expect(csv[1]).to eq([
        nil,
        claim.first_name,
        claim.middle_name,
        claim.surname,
        claim.national_insurance_number,
        "F",
        start_of_month.strftime("%m/%d/%Y"),
        (start_of_month + 7.days).strftime("%m/%d/%Y"),
        claim.date_of_birth.strftime("%m/%d/%Y"),
        claim.email_address,
        claim.address_line_1,
        claim.address_line_2,
        claim.address_line_3,
        claim.address_line_4,
        nil,
        claim.postcode,
        "United Kingdom",
        "BR",
        "0",
        "3",
        "A",
        "T",
        "1",
        claim.full_name,
        claim.bank_sort_code,
        claim.bank_account_number,
        "Scheme B",
        claim.eligibility.student_loan_repayment_amount.to_s,
        claim.reference,
      ])
    end
  end
end
