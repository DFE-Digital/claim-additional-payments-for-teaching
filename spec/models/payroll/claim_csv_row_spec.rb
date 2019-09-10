require "rails_helper"

RSpec.describe Payroll::ClaimCsvRow do
  subject { described_class.new(claim) }
  let(:claim) { build(:claim) }

  describe "to_s" do
    let(:row) { CSV.parse(subject.to_s).first }
    let(:start_of_month) { Date.today.at_beginning_of_month }

    let(:claim) do
      build(:claim, :submittable,
        payroll_gender: :female,
        date_of_birth: Date.new(1980, 12, 1),
        student_loan_plan: StudentLoans::PLAN_2,
        bank_sort_code: "001122",
        bank_account_number: "01234567",
        address_line_1: "1 Test Road",
        postcode: "AB1 2CD",
        eligibility: build(:student_loans_eligibility, :eligible))
    end

    it "generates a csv row" do
      expect(row).to eq([
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
        claim.postcode,
        nil,
        nil,
        nil,
        nil,
        "United Kingdom",
        "BR",
        "0",
        "3",
        "A",
        "T",
        "2",
        claim.full_name,
        claim.bank_sort_code,
        claim.bank_account_number,
        "Student Loans",
        claim.eligibility.student_loan_repayment_amount.to_s,
        claim.reference,
      ])
    end

    it "escapes fields with strings that could be dangerous in Microsoft Excel and friends" do
      claim.address_line_1 = "=ActiveCell.Row-1,14"

      expect(row[Payroll::ClaimsCsv::FIELDS_WITH_HEADERS.find_index { |k, _| k == :address_line_1 }]).to eq("\\#{claim.address_line_1}")
    end
  end
end
