require "rails_helper"

RSpec.describe TslrClaimCsvRow do
  subject { described_class.new(claim) }
  let(:claim) { build(:tslr_claim) }

  describe "to_s" do
    let(:date_of_birth) { "01/12/1980" }
    let(:student_loan_repayment_amount) { "£1000.0" }
    let(:submitted_at) { "01/01/2019 13:00" }
    let(:row) { CSV.parse(subject.to_s).first }

    let(:claim) do
      build(:tslr_claim, :submittable,
        date_of_birth: Date.parse(date_of_birth),
        student_loan_repayment_amount: student_loan_repayment_amount.delete("£").to_i,
        student_loan_plan: StudentLoans::PLAN_2,
        submitted_at: DateTime.parse(submitted_at),
        eligibility: build(:student_loans_eligibility, :eligible, mostly_teaching_eligible_subjects: true))
    end

    it "generates a csv row" do
      expect(row).to eq([
        claim.reference,
        submitted_at,
        claim.qts_award_year,
        claim.eligibility.claim_school.name,
        claim.eligibility.employment_status.humanize,
        claim.eligibility.current_school.name,
        claim.full_name,
        claim.address_line_1,
        claim.address_line_2,
        claim.address_line_3,
        claim.address_line_4,
        claim.postcode,
        date_of_birth,
        claim.payroll_gender,
        claim.teacher_reference_number,
        claim.national_insurance_number,
        StudentLoans::PLAN_2.humanize,
        "=\"#{claim.email_address}\"",
        "Yes",
        claim.bank_sort_code,
        claim.bank_account_number,
        student_loan_repayment_amount,
      ])
    end

    it "escapes fields with strings that could be dangerous in Microsoft Excel and friends" do
      claim.address_line_1 = "equals=sign"
      claim.address_line_2 = "minus-sign"
      claim.address_line_3 = "plus+sign"
      claim.address_line_4 = "at@symbol"
      claim.postcode = "=SUM(A1, A2)"
      claim.email_address = "valid=email@domain.tld"

      expect(row[TslrClaimsCsv::FIELDS.index(:address_line_1)]).to eq("=\"#{claim.address_line_1}\"")
      expect(row[TslrClaimsCsv::FIELDS.index(:address_line_2)]).to eq("=\"#{claim.address_line_2}\"")
      expect(row[TslrClaimsCsv::FIELDS.index(:address_line_3)]).to eq("=\"#{claim.address_line_3}\"")
      expect(row[TslrClaimsCsv::FIELDS.index(:address_line_4)]).to eq("=\"#{claim.address_line_4}\"")
      expect(row[TslrClaimsCsv::FIELDS.index(:postcode)]).to eq("=\"#{claim.postcode}\"")
      expect(row[TslrClaimsCsv::FIELDS.index(:email_address)]).to eq("=\"#{claim.email_address}\"")
    end

    it "escaped fields are properly quoted when converted to CSV" do
      claim.postcode = "=SUM(A1, A2)"

      expect(CSV.generate_line(row)).to include('"=""' + claim.postcode + '"""')
    end
  end
end
