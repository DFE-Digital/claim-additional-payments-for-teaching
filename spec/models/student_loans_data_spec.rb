require "rails_helper"

RSpec.describe StudentLoansData do
  describe "scopes" do
    describe ".by_nino" do
      let!(:applicant_a_slc_record_one) { create(:student_loans_data, nino: "QQ123456A", amount: 100, plan_type_of_deduction: 2) }
      let!(:applicant_a_slc_record_two) { create(:student_loans_data, nino: "QQ123456A", amount: 50, plan_type_of_deduction: 1) }
      let!(:applicant_b_slc_record_one) { create(:student_loans_data, nino: "QQ123456B", amount: 60, plan_type_of_deduction: 1) }

      it "returns records for a given NINO", :aggregate_failures do
        expect(described_class.by_nino("QQ123456A")).to match([applicant_a_slc_record_one, applicant_a_slc_record_two])
        expect(described_class.by_nino("QQ123456B")).to match([applicant_b_slc_record_one])
      end

      describe ".repaying_plan_types" do
        it "returns the plan types for a given NINO", :aggregate_failures do
          expect(described_class.by_nino("QQ123456A").repaying_plan_types).to eq("plan_1_and_2")
          expect(described_class.by_nino("QQ123456B").repaying_plan_types).to eq("plan_1")
          expect(described_class.by_nino("QQ123456C").repaying_plan_types).to eq(nil)
        end
      end

      describe ".total_repayment_amount" do
        it "returns the total repayment amount a given NINO", :aggregate_failures do
          expect(described_class.by_nino("QQ123456A").total_repayment_amount).to eq(150)
          expect(described_class.by_nino("QQ123456B").total_repayment_amount).to eq(60)
          expect(described_class.by_nino("QQ123456C").total_repayment_amount).to eq(0)
        end
      end
    end
  end
end
