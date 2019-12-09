require "rails_helper"

RSpec.describe Payroll::PaymentCsvRow do
  subject { described_class.new(payment) }
  let(:claim) { build(:claim) }

  describe "to_s with an approved claim that has a payment" do
    let(:row) { CSV.parse(subject.to_s).first }
    let(:payment_award_amount) { BigDecimal("1234.56") }
    let(:payment) { build(:payment, award_amount: payment_award_amount, claims: [claim]) }
    let(:claim) do
      build(:claim, :approved,
        payroll_gender: :female,
        date_of_birth: Date.new(1980, 12, 1),
        student_loan_plan: StudentLoan::PLAN_2,
        bank_sort_code: "001122",
        bank_account_number: "01234567",
        banking_name: "Jo Bloggs",
        building_society_roll_number: "1234/12345678",
        address_line_1: "1 Test Road",
        postcode: "AB1 2CD")
    end

    it "generates a csv row" do
      travel_to Date.new(2019, 9, 26) do
        expect(row).to eq([
          "Captain",
          claim.first_name,
          claim.middle_name,
          claim.surname,
          claim.national_insurance_number,
          "F",
          "20190909",
          "20190915",
          claim.date_of_birth.strftime("%Y%m%d"),
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
          claim.banking_name,
          claim.bank_sort_code,
          claim.bank_account_number,
          claim.building_society_roll_number,
          "Student Loans",
          payment_award_amount.to_s,
          claim.reference,
        ])
      end
    end

    describe "start and end dates" do
      context "when the first of the month is a Friday" do
        it "returns the date of the second Monday and Sunday" do
          travel_to Date.parse "20 February 2019" do
            row = CSV.parse(subject.to_s).first
            expect(row[6]).to eq "20190211"
            expect(row[7]).to eq "20190217"
          end
        end
      end

      context "when the first of the month is a Sunday" do
        it "returns the date of the second Monday and Sunday" do
          travel_to Date.parse "9 July 2040" do
            row = CSV.parse(subject.to_s).first
            expect(row[6]).to eq "20400709"
            expect(row[7]).to eq "20400715"
          end
        end
      end

      context "when the first of the month is a Monday" do
        it "returns the date of the second Monday and Sunday" do
          travel_to Date.parse "1 June 2020" do
            row = CSV.parse(subject.to_s).first
            expect(row[6]).to eq "20200608"
            expect(row[7]).to eq "20200614"
          end
        end
      end
    end

    it "escapes fields with strings that could be dangerous in Microsoft Excel and friends" do
      claim.address_line_1 = "=ActiveCell.Row-1,14"

      expect(row[Payroll::PaymentsCsv::FIELDS_WITH_HEADERS.find_index { |k, _| k == :address_line_1 }]).to eq("\\#{claim.address_line_1}")
    end
  end
end
