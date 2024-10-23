require "rails_helper"

RSpec.describe StudentLoansData do
  let!(:applicant_a_slc_record_one) { create(:student_loans_data, nino: "QQ123456A", date_of_birth: Date.new(1980, 1, 1), amount: 100, plan_type_of_deduction: 2) }
  let!(:applicant_a_slc_record_two) { create(:student_loans_data, nino: "QQ123456A", date_of_birth: Date.new(1980, 1, 1), amount: 50, plan_type_of_deduction: 1) }
  let!(:applicant_b_slc_record_one) { create(:student_loans_data, nino: "QQ123456B", date_of_birth: Date.new(1990, 1, 1), amount: 60, plan_type_of_deduction: 1) }
  let!(:applicant_b_duplicate) { create(:student_loans_data, nino: "QQ123456B", date_of_birth: Date.new(1990, 1, 1), amount: 60, plan_type_of_deduction: 1) }

  def query_results_by(**)
    described_class.where(**)
  end

  describe ".repaying_plan_types" do
    it "returns the plan types for the query results", :aggregate_failures do
      expect(query_results_by(nino: "QQ123456A").repaying_plan_types).to eq("plan_1_and_2")
      expect(query_results_by(nino: "QQ123456B").repaying_plan_types).to eq("plan_1")
      expect(query_results_by(nino: "QQ123456C").repaying_plan_types).to eq(nil)
    end
  end

  describe ".total_repayment_amount" do
    it "returns the total repayment amount for the query results", :aggregate_failures do
      expect(query_results_by(nino: "QQ123456A").total_repayment_amount).to eq(150)
      expect(query_results_by(nino: "QQ123456B").total_repayment_amount).to eq(60)
      expect(query_results_by(nino: "QQ123456C").total_repayment_amount).to eq(0)
    end
  end
end
