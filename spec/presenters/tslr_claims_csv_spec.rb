require "rails_helper"

RSpec.describe TslrClaimsCsv do
  before do
    create(:tslr_claim, :submitted)
  end

  subject { described_class.new(claims) }
  let(:claims) { TslrClaim.all.order(:submitted_at) }
  let(:claim) { claims.first }

  describe "file" do
    let(:file) { subject.file }
    let(:csv) { CSV.read(file) }

    it "returns the correct headers" do
      expect(csv[0]).to eq([
        "Reference",
        "Submitted at",
        "Award Year",
        "Claim School",
        "Employment Status",
        "Current School",
        "Applicant Name",
        "Address 1",
        "Address 2",
        "Address 3",
        "Address 4",
        "Postcode",
        "Date of Birth",
        "Teacher Reference",
        "NI Number",
        "Student Loan Repayment Plan",
        "Email",
        "Mostly Teaching Eligible Subjects?",
        "Sort Code",
        "Account Number",
        "Repayment Amount",
      ])
    end

    it "returns the correct rows" do
      expect(csv[1]).to eq([
        claim.reference,
        claim.submitted_at.strftime("%d/%m/%Y %H:%M"),
        claim.qts_award_year,
        claim.claim_school_name,
        claim.employment_status.humanize,
        claim.current_school_name,
        claim.full_name,
        claim.address_line_1,
        nil,
        claim.address_line_3,
        nil,
        claim.postcode,
        claim.date_of_birth.strftime("%d/%m/%Y"),
        claim.teacher_reference_number,
        claim.national_insurance_number,
        claim.student_loan_plan.humanize,
        claim.email_address,
        claim.mostly_teaching_eligible_subjects ? "Yes" : "No",
        claim.bank_sort_code,
        claim.bank_account_number,
        "£#{claim.student_loan_repayment_amount}",
      ])
    end
  end
end
