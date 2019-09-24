require "rails_helper"

RSpec.describe StudentLoans::ClaimsCsv do
  before do
    create(:claim, :submitted)
  end

  subject { described_class.new(claims) }
  let(:claims) { Claim.all.order(:submitted_at) }
  let(:claim) { claims.first }
  let(:eligibility) { claim.eligibility }

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
        "First name",
        "Middle name",
        "Surname",
        "Address 1",
        "Address 2",
        "Address 3",
        "Address 4",
        "Postcode",
        "Date of Birth",
        "Payroll Gender",
        "Teacher Reference",
        "NI Number",
        "Student Loan Repayment Plan",
        "Email",
        "Had Leadership Position?",
        "Mostly Performed Leadership Duties?",
        "Biology Taught?",
        "Chemistry Taught?",
        "Computer Science Taught?",
        "Languages Taught?",
        "Physics Taught?",
        "Sort Code",
        "Account Number",
        "Repayment Amount",
      ])
    end

    it "returns the correct rows" do
      expect(csv[1]).to eq([
        claim.reference,
        claim.submitted_at.strftime("%d/%m/%Y %H:%M"),
        eligibility.qts_award_year,
        eligibility.selected_employment.school_name,
        eligibility.employment_status.humanize,
        eligibility.current_school_name,
        claim.first_name,
        claim.middle_name,
        claim.surname,
        claim.address_line_1,
        nil,
        claim.address_line_3,
        nil,
        claim.postcode,
        claim.date_of_birth.strftime("%d/%m/%Y"),
        claim.payroll_gender,
        claim.teacher_reference_number,
        claim.national_insurance_number,
        claim.student_loan_plan.humanize,
        claim.email_address,
        eligibility.had_leadership_position? ? "Yes" : "No",
        eligibility.mostly_performed_leadership_duties? ? "Yes" : "No",
        eligibility.selected_employment.biology_taught? ? "Yes" : "No",
        eligibility.selected_employment.chemistry_taught? ? "Yes" : "No",
        eligibility.selected_employment.computer_science_taught? ? "Yes" : "No",
        eligibility.selected_employment.languages_taught? ? "Yes" : "No",
        eligibility.selected_employment.physics_taught? ? "Yes" : "No",
        claim.bank_sort_code,
        claim.bank_account_number,
        "£#{eligibility.selected_employment.student_loan_repayment_amount}",
      ])
    end
  end
end
