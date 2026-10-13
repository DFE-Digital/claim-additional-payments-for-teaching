require "rails_helper"

RSpec.describe Policies::EarlyYearsTeachersFinancialIncentivePayments::AdminClaimPresenter do
  describe "#personal_details" do
    it "returns the personal details for claims before the 2026 academic year" do
      claim = build(
        :claim,
        policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
        academic_year: AcademicYear.new(2025),
        first_name: "Alex",
        surname: "Teacher",
        date_of_birth: Date.new(1980, 4, 5),
        national_insurance_number: "AB123456C",
        address_line_1: "1 Test Road",
        address_line_2: "Test Town",
        postcode: "TE1 1ST",
        email_address: "alex@example.com",
        banking_name: "Alex Teacher",
        bank_account_number: "12345678",
        bank_sort_code: "123456",
        eligibility_attributes: {
          teacher_reference_number: "1234567"
        }
      )

      expect(described_class.new(claim).personal_details).to eq [
        ["Teacher reference number", "1234567"],
        ["Full name", "Alex Teacher"],
        ["Date of birth", "5 April 1980"],
        ["National Insurance number", "AB123456C"],
        ["Address", "1 Test Road<br>Test Town<br>TE1 1ST"],
        ["Email address", "alex@example.com"],
        ["Banking name", "Alex Teacher"],
        ["Bank account number", "12345678"],
        ["Bank sort code", "123456"]
      ]
    end

    it "returns the TRS and claimant NI numbers for claims from the 2026 academic year" do
      claim = build(
        :claim,
        policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
        academic_year: AcademicYear.new(2026),
        first_name: "Alex",
        surname: "Teacher",
        date_of_birth: Date.new(1980, 4, 5),
        national_insurance_number: "AB123456C",
        address_line_1: "1 Test Road",
        address_line_2: "Test Town",
        postcode: "TE1 1ST",
        email_address: "alex@example.com",
        banking_name: "Alex Teacher",
        bank_account_number: "12345678",
        bank_sort_code: "123456",
        eligibility_attributes: {
          teacher_reference_number: "1234567",
          trs_national_insurance_number: "CD987654A"
        }
      )

      expect(described_class.new(claim).personal_details).to eq [
        ["Teacher reference number", "1234567"],
        ["Full name", "Alex Teacher"],
        ["Date of birth", "5 April 1980"],
        ["National Insurance number held by teacher pension service", "CD987654A"],
        ["National Insurance number entered", "AB123456C"],
        ["Address", "1 Test Road<br>Test Town<br>TE1 1ST"],
        ["Email address", "alex@example.com"],
        ["Banking name", "Alex Teacher"],
        ["Bank account number", "12345678"],
        ["Bank sort code", "123456"]
      ]
    end
  end
end
