require "rails_helper"

RSpec.describe TslrClaimCsvRow do
  subject { described_class.new(claim) }
  let(:claim) { build(:claim) }

  describe "to_s" do
    let(:date_of_birth) { "01/12/1980" }
    let(:submitted_at) { "01/01/2019 13:00" }
    let(:row) { CSV.parse(subject.to_s).first }

    let(:claim) do
      build(:claim, :submittable,
        date_of_birth: Date.parse(date_of_birth),
        student_loan_plan: StudentLoans::PLAN_2,
        submitted_at: DateTime.parse(submitted_at),
        eligibility: build(:student_loans_eligibility, :eligible, mostly_teaching_eligible_subjects: true))
    end
    let(:eligibility) { claim.eligibility }

    it "generates a csv row" do
      expect(row).to eq([
        claim.reference,
        submitted_at,
        eligibility.qts_award_year,
        eligibility.claim_school.name,
        eligibility.employment_status.humanize,
        eligibility.current_school.name,
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
        claim.email_address,
        "Yes",
        claim.bank_sort_code,
        claim.bank_account_number,
        "£#{eligibility.student_loan_repayment_amount}",
      ])
    end

    it "escapes fields with strings that could be dangerous in Microsoft Excel and friends" do
      claim.address_line_1 = "=ActiveCell.Row-1,14"

      expect(row[TslrClaimsCsv::FIELDS.index(:address_line_1)]).to eq("\\#{claim.address_line_1}")
    end
  end
end
