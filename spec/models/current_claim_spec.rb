require "rails_helper"

RSpec.describe CurrentClaim, type: :model do
  context "Two claims - ECP and LUP" do
    let(:ecp_policy) { EarlyCareerPayments }
    let(:lup_policy) { LevellingUpPremiumPayments }
    let(:ecp_claim) { build(:claim, academic_year: "2022/2023", policy: ecp_policy) }
    let(:lup_claim) { build(:claim, academic_year: "2022/2023", policy: lup_policy) }
    let(:school) { create(:school) }

    describe "#attributes=" do
      it "sets the attributes on both claims" do
        cc = CurrentClaim.new(claims: [ecp_claim, lup_claim])

        expect { cc.attributes = {"eligibility_attributes" => {"current_school_id" => school.id}} }
          .to change { cc.claims.first.school&.id }.from(nil).to(school.id)
          .and change { cc.claims.last.school&.id }.from(nil).to(school.id)
      end
    end

    describe "#save!" do
      it "saves both claims" do
        cc = CurrentClaim.new(claims: [ecp_claim, lup_claim])
        cc.attributes = {"eligibility_attributes" => {"current_school_id" => school.id}}

        cc.save!

        expect(ecp_claim.reload.school.id).to eq(school.id)
        expect(lup_claim.reload.school.id).to eq(school.id)
      end
    end

    describe "#reset_dependent_answers" do
      it "calls reset reset_dependent_answers on both claims" do
        cc = CurrentClaim.new(claims: [ecp_claim, lup_claim])

        expect(ecp_claim).to receive(:reset_dependent_answers)
        expect(lup_claim).to receive(:reset_dependent_answers)

        cc.reset_dependent_answers
      end
    end

    describe "#eligibility.reset_dependent_answers" do
      let(:ecp_claim) { build(:claim, academic_year: "2022/2023", policy: ecp_policy) }
      let(:lup_claim) { build(:claim, academic_year: "2022/2023", policy: lup_policy) }

      it "calls reset_dependent_answers on both claims' eligibility" do
        expect(ecp_claim.eligibility).to receive(:reset_dependent_answers)
        expect(lup_claim.eligibility).to receive(:reset_dependent_answers)

        cc = CurrentClaim.new(claims: [ecp_claim, lup_claim])
        cc.reset_eligibility_dependent_answers
      end
    end

    describe "#for_policy" do
      let(:maths_and_physics_policy) { MathsAndPhysics }
      let(:student_loans_policy) { StudentLoans }
      let(:maths_and_physics_claim) { build(:claim, academic_year: "2022/2023", policy: maths_and_physics_policy) }
      let(:student_loans_claim) { build(:claim, academic_year: "2022/2023", policy: student_loans_policy) }

      it "returns the single maths and physics claim" do
        cc = CurrentClaim.new(claims: [maths_and_physics_claim])
        expect(cc.for_policy(MathsAndPhysics)).to eq(maths_and_physics_claim)
      end

      it "returns the single student loans claims" do
        cc = CurrentClaim.new(claims: [student_loans_claim])
        expect(cc.for_policy(StudentLoans)).to eq(student_loans_claim)
      end

      context "multiple claims" do
        let(:cc) { CurrentClaim.new(claims: [ecp_claim, lup_claim]) }

        it "returns the ECP claim with 2 claims" do
          expect(cc.for_policy(EarlyCareerPayments)).to eq(ecp_claim)
        end

        it "returns the LUP claim with 2 claims" do
          expect(cc.for_policy(LevellingUpPremiumPayments)).to eq(lup_claim)
        end
      end
    end
  end
end
