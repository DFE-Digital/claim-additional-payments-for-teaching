require "rails_helper"

RSpec.describe TslrClaimCsvRow do
  subject { described_class.new(claim) }
  let(:claim) { create(:tslr_claim) }

  describe "to_s" do
    let(:claim_school) { "Claim School" }
    let(:current_school) { "Current School" }
    let(:date_of_birth) { "01/12/1980" }
    let(:employment_status) { "Different school" }
    let(:mostly_teaching_eligible_subjects) { "Yes" }
    let(:student_loan_repayment_amount) { "£1,000.00" }
    let(:submitted_at) { "01/01/2019 13:00" }
    let(:row) { CSV.parse(subject.to_s).first }

    let(:claim) do
      create(:tslr_claim, :submittable,
        claim_school: create(:school, name: claim_school),
        current_school: create(:school, name: current_school),
        employment_status: TslrClaim.employment_statuses[employment_status.parameterize.underscore],
        date_of_birth: Date.parse(date_of_birth),
        mostly_teaching_eligible_subjects: mostly_teaching_eligible_subjects == "Yes",
        student_loan_repayment_amount: student_loan_repayment_amount.delete("£").delete(",").to_i,
        submitted_at: DateTime.parse(submitted_at))
    end

    it "generates a csv row" do
      expect(row).to eq([
        claim.reference,
        submitted_at,
        claim.qts_award_year,
        claim_school,
        employment_status,
        current_school,
        claim.full_name,
        claim.address_line_1,
        claim.address_line_2,
        claim.address_line_3,
        claim.address_line_4,
        claim.postcode,
        date_of_birth,
        claim.teacher_reference_number,
        claim.national_insurance_number,
        claim.email_address,
        mostly_teaching_eligible_subjects,
        claim.bank_sort_code,
        claim.bank_account_number,
        student_loan_repayment_amount,
      ])
    end
  end
end
