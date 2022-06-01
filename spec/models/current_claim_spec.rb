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
        cc = described_class.new(claims: [ecp_claim, lup_claim])

        expect { cc.attributes = {"eligibility_attributes" => {"current_school_id" => school.id}} }
          .to change { cc.claims.first.school&.id }.from(nil).to(school.id)
          .and change { cc.claims.last.school&.id }.from(nil).to(school.id)
      end
    end

    describe "#save!" do
      it "saves both claims" do
        cc = described_class.new(claims: [ecp_claim, lup_claim])
        cc.attributes = {"eligibility_attributes" => {"current_school_id" => school.id}}

        cc.save!

        expect(ecp_claim.reload.school.id).to eq(school.id)
        expect(lup_claim.reload.school.id).to eq(school.id)
      end
    end

    describe "#reset_dependent_answers" do
      it "calls reset reset_dependent_answers on both claims" do
        cc = described_class.new(claims: [ecp_claim, lup_claim])

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

        cc = described_class.new(claims: [ecp_claim, lup_claim])
        cc.reset_eligibility_dependent_answers
      end
    end

    describe "#for_policy" do
      let(:maths_and_physics_policy) { MathsAndPhysics }
      let(:student_loans_policy) { StudentLoans }
      let(:maths_and_physics_claim) { build(:claim, academic_year: "2022/2023", policy: maths_and_physics_policy) }
      let(:student_loans_claim) { build(:claim, academic_year: "2022/2023", policy: student_loans_policy) }

      it "returns the single maths and physics claim" do
        cc = described_class.new(claims: [maths_and_physics_claim])
        expect(cc.for_policy(MathsAndPhysics)).to eq(maths_and_physics_claim)
      end

      it "returns the single student loans claims" do
        cc = described_class.new(claims: [student_loans_claim])
        expect(cc.for_policy(StudentLoans)).to eq(student_loans_claim)
      end

      context "multiple claims" do
        let(:cc) { described_class.new(claims: [ecp_claim, lup_claim]) }

        it "returns the ECP claim with 2 claims" do
          expect(cc.for_policy(EarlyCareerPayments)).to eq(ecp_claim)
        end

        it "returns the LUP claim with 2 claims" do
          expect(cc.for_policy(LevellingUpPremiumPayments)).to eq(lup_claim)
        end
      end
    end

    describe "#ineligible?" do
      subject { cc.ineligible? }

      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :eligible) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible) }

      let(:ecp_claim) { build(:claim, academic_year: "2022/2023", eligibility: ecp_eligibility) }
      let(:lup_claim) { build(:claim, academic_year: "2022/2023", eligibility: lup_eligibility) }

      let(:cc) { described_class.new(claims: [ecp_claim, lup_claim]) }

      context "when both claims are eligible" do
        let(:ecp_eligibility) { build(:early_career_payments_eligibility, :eligible) }

        it { is_expected.to be false }
      end

      context "when ECP claims is ineligible" do
        let(:ecp_eligibility) { build(:early_career_payments_eligibility, :ineligible) }

        it { is_expected.to be false }
      end

      context "when LUP claims is ineligible" do
        let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :ineligible) }

        it { is_expected.to be false }
      end

      context "when both claims are ineligible" do
        let(:ecp_eligibility) { build(:early_career_payments_eligibility, :ineligible) }
        let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :ineligible) }

        it { is_expected.to be true }
      end
    end

    describe "#editable_attributes" do
      subject { cc.editable_attributes }

      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :eligible) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible) }

      let(:ecp_claim) { build(:claim, academic_year: "2022/2023", eligibility: ecp_eligibility) }
      let(:lup_claim) { build(:claim, academic_year: "2022/2023", eligibility: lup_eligibility) }

      let(:cc) { described_class.new(claims: [ecp_claim, lup_claim]) }

      context "when current claim has ECP and LUP claims" do
        expected = [
          :nqt_in_academic_year_after_itt,
          :current_school_id,
          :employed_as_supply_teacher,
          :has_entire_term_contract,
          :employed_directly,
          :subject_to_formal_performance_action,
          :subject_to_disciplinary_action,
          :qualification,
          :eligible_itt_subject,
          :teaching_subject_now,
          :itt_academic_year,
          :award_amount,
          :eligible_degree_subject
        ]

        it { is_expected.to eq expected }
      end

      context "when current claim has an ECP claim" do
        let(:cc) { described_class.new(claims: [ecp_claim]) }

        expected = [
          :nqt_in_academic_year_after_itt,
          :current_school_id,
          :employed_as_supply_teacher,
          :has_entire_term_contract,
          :employed_directly,
          :subject_to_formal_performance_action,
          :subject_to_disciplinary_action,
          :qualification,
          :eligible_itt_subject,
          :teaching_subject_now,
          :itt_academic_year,
          :award_amount
        ]

        it { is_expected.to eq expected }
      end

      context "when current claim has an LUP claim" do
        let(:cc) { described_class.new(claims: [lup_claim]) }

        expected = [
          :nqt_in_academic_year_after_itt,
          :current_school_id,
          :employed_as_supply_teacher,
          :has_entire_term_contract,
          :employed_directly,
          :subject_to_formal_performance_action,
          :subject_to_disciplinary_action,
          :qualification,
          :eligible_itt_subject,
          :teaching_subject_now,
          :itt_academic_year,
          :award_amount,
          :eligible_degree_subject
        ]

        it { is_expected.to eq expected }
      end
    end
  end
end
