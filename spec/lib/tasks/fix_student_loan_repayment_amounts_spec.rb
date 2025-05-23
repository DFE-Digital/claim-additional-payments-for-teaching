require "rails_helper"

Rails.application.load_tasks

RSpec.describe "fix_tslr_student_loan_amounts" do
  around do |example|
    original_stdout = $stdout
    original_stderr = $stderr

    $stdout = File.open(File::NULL, "w")
    $stderr = File.open(File::NULL, "w")

    example.run

    $stdout = original_stdout
    $stderr = original_stderr
  end

  before do
    create(:student_loans_data, nino: "QQ123456A", date_of_birth: Date.new(1980, 1, 1), amount: 100, plan_type_of_deduction: 2)
    create(:student_loans_data, nino: "QQ123456A", date_of_birth: Date.new(1980, 1, 1), amount: 50, plan_type_of_deduction: 1)
    create(:student_loans_data, nino: "QQ123456B", date_of_birth: Date.new(1990, 1, 1), amount: 60, plan_type_of_deduction: 1)
    create(:student_loans_data, nino: "QQ123456B", date_of_birth: Date.new(1990, 1, 1), amount: 60, plan_type_of_deduction: 1) # duplicate
    claim_1
    claim_2
    create(:payment, :confirmed, claims: [claim_1])
    create(:payment, :confirmed, claims: [claim_2], payroll_run: Claim.first.payments.last.payroll_run)
  end

  let(:claim_1) do
    create(:claim, :submitted, policy: Policies::StudentLoans, academic_year: AcademicYear.current, national_insurance_number: "QQ123456A", date_of_birth: Date.new(1980, 1, 1),
      eligibility_attributes: {award_amount: 150})
  end

  let(:claim_2) do
    create(:claim, :submitted, policy: Policies::StudentLoans, academic_year: AcademicYear.current, national_insurance_number: "QQ123456B", date_of_birth: Date.new(1990, 1, 1),
      eligibility_attributes: {award_amount: 120})
  end

  context "with the run argument" do
    subject { Rake::Task["fix_tslr_student_loan_amounts"].invoke }

    before { allow(ARGV).to receive(:[]) { "run" } }

    it "updates TSLR claims that have incorrect amounts" do
      subject
      expect(claim_1.reload.eligibility.award_amount).to eq 150
      expect(claim_2.reload.eligibility.award_amount).to eq 60
    end
  end
end
