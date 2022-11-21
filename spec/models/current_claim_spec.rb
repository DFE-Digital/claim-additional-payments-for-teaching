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

    describe "#save" do
      subject { current_claim.save }

      let(:current_claim) { described_class.new(claims: [ecp_claim, lup_claim]) }

      context "when claim attributes are invalid" do
        let(:lup_claim) { build(:claim, academic_year: "2022/2023", policy: lup_policy, email_address: "invalid") }

        it "calls save on both claims" do
          expect(lup_claim).to receive(:save)
          expect(ecp_claim).to receive(:save)
          subject
        end

        it { is_expected.to be false }
      end

      context "when claim attributes are valid" do
        let(:lup_claim) { build(:claim, academic_year: "2022/2023", policy: lup_policy, email_address: "email@example.com") }

        it "calls save on both claims" do
          expect(lup_claim).to receive(:save)
          expect(ecp_claim).to receive(:save)
          subject
        end

        it { is_expected.to be true }
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

    describe "#policies" do
      let(:cc) { described_class.new(claims: [ecp_claim, lup_claim]) }

      specify { expect(cc.policies).to contain_exactly(EarlyCareerPayments, LevellingUpPremiumPayments) }
    end

    describe "#ineligible?" do
      subject { cc.ineligible? }

      let!(:policy_configuration) { create(:policy_configuration, :additional_payments) }

      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :eligible) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible) }

      let(:ecp_claim) { build(:claim, policy: EarlyCareerPayments, academic_year: "2021/2022", eligibility: ecp_eligibility) }
      let(:lup_claim) { build(:claim, policy: LevellingUpPremiumPayments, academic_year: "2022/2023", eligibility: lup_eligibility) }

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

    describe "#eligible_now?" do
      subject { cc.eligible_now? }

      let!(:policy_configuration) { create(:policy_configuration, :additional_payments) }

      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :eligible) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible) }

      let(:ecp_claim) { build(:claim, policy: EarlyCareerPayments, eligibility: ecp_eligibility) }
      let(:lup_claim) { build(:claim, policy: LevellingUpPremiumPayments, eligibility: lup_eligibility) }

      let(:cc) { described_class.new(claims: [ecp_claim, lup_claim]) }

      context "when both claims are eligible" do
        it { is_expected.to be true }
      end

      context "when ECP claim is ineligible" do
        let(:ecp_eligibility) { build(:early_career_payments_eligibility, :ineligible) }

        it { is_expected.to be true }
      end

      context "when LUP claim is ineligible" do
        let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :ineligible) }

        it { is_expected.to be true }
      end

      context "when both claims are ineligible" do
        let(:ecp_eligibility) { build(:early_career_payments_eligibility, :ineligible) }
        let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :ineligible) }

        it { is_expected.to be false }
      end
    end

    describe "#editable_attributes" do
      subject { cc.editable_attributes }

      let!(:policy_configuration) { create(:policy_configuration, :additional_payments) }

      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :eligible) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible) }

      let(:ecp_claim) { build(:claim, policy: EarlyCareerPayments, academic_year: "2022/2023", eligibility: ecp_eligibility) }
      let(:lup_claim) { build(:claim, policy: LevellingUpPremiumPayments, academic_year: "2022/2023", eligibility: lup_eligibility) }

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
          :itt_academic_year
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
          :eligible_degree_subject
        ]

        it { is_expected.to eq expected }
      end
    end

    describe "#eligible_now" do
      subject(:result) { cc.eligible_now }

      let!(:policy_configuration) { create(:policy_configuration, :additional_payments) }

      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :ineligible) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible) }

      let(:ecp_claim) { create(:claim, policy: EarlyCareerPayments, eligibility: ecp_eligibility) }
      let(:lup_claim) { create(:claim, policy: LevellingUpPremiumPayments, eligibility: lup_eligibility) }

      let(:cc) { described_class.new(claims: [ecp_claim, lup_claim]) }

      context "when one claim is eligible and one is ineligible" do
        it "returns only the eligible claim" do
          expect(result).to contain_exactly(lup_claim)
        end
      end

      context "when both claims are eligible" do
        let(:ecp_eligibility) { build(:early_career_payments_eligibility, :eligible) }

        it "returns both claims" do
          expect(result).to contain_exactly(ecp_claim, lup_claim)
        end
      end

      context "when both claims are ineligible" do
        let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :ineligible) }

        it { is_expected.to be_empty }
      end
    end

    describe "#eligible_now_and_sorted" do
      subject(:result) { cc.eligible_now_and_sorted }

      let!(:policy_configuration) { create(:policy_configuration, :additional_payments) }

      let(:ecp_claim) { create(:claim, policy: EarlyCareerPayments, eligibility: ecp_eligibility) }
      let(:lup_claim) { create(:claim, policy: LevellingUpPremiumPayments, eligibility: lup_eligibility) }
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :eligible, award_amount: ecp_amount) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible, award_amount: lup_amount) }

      let(:cc) { described_class.new(claims: [ecp_claim, lup_claim]) }

      context "with identical award amounts" do
        let(:ecp_amount) { 2000.0 }
        let(:lup_amount) { ecp_amount }

        it "orders the claims by name" do
          expect(result).to eq([ecp_claim, lup_claim])
        end
      end

      context "with different award amounts" do
        let(:ecp_amount) { 1000.0 }
        let(:lup_amount) { 2000.0 }

        it "orders the claims by highest award amount" do
          expect(result).to eq([lup_claim, ecp_claim])
        end
      end

      context "with different award amounts other way around" do
        let(:ecp_amount) { 3000.0 }
        let(:lup_amount) { 2000.0 }

        it "orders the claims by highest award amount" do
          expect(result).to eq([ecp_claim, lup_claim])
        end
      end
    end

    describe "#submit!" do
      let!(:policy_configuration) { create(:policy_configuration, :additional_payments) }
      let!(:ecp_claim) { create(:claim, :submittable, policy: ecp_policy, eligibility: ecp_eligibility) }
      let!(:lup_claim) { create(:claim, :submittable, policy: lup_policy, eligibility: lup_eligibility) }

      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :eligible, award_amount: 1000.0) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible, award_amount: 2000.0) }

      let(:cc) { described_class.new(claims: Claim.all) }

      context "when a claim for the supplied policy is found" do
        let(:policy) { ecp_claim.policy }

        before { cc.submit!(policy) }

        it "destroys the other claims" do
          expect { lup_claim.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end

        it "removes the other claims from the set" do
          expect(cc.claims.map(&:policy)).to eq([policy])
        end

        it "submits the specified claim" do
          expect(ecp_claim.reload).to be_submitted
        end

        it "stores the policy options provided on submission for both eligible policies" do
          policy_options_provided = [
            {"policy" => "LevellingUpPremiumPayments", "award_amount" => "2000.0"},
            {"policy" => "EarlyCareerPayments", "award_amount" => "1000.0"}
          ]

          expect(ecp_claim.reload.policy_options_provided).to eq policy_options_provided
        end
      end

      context "when only ECP is eligible" do
        let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :ineligible) }
        let!(:lup_claim) { create(:claim, :submittable, policy: LevellingUpPremiumPayments, eligibility: lup_eligibility) }
        let(:cc) { described_class.new(claims: Claim.where(id: [ecp_claim.id, lup_claim.id])) }
        let(:policy) { ecp_claim.policy }

        before { cc.submit!(policy) }

        it "stores the policy option provided on submission just for the ECP policy" do
          policy_options_provided = [
            {"policy" => "EarlyCareerPayments", "award_amount" => "1000.0"}
          ]

          expect(ecp_claim.reload.policy_options_provided).to eq policy_options_provided
        end
      end

      context "when only LUP is eligible" do
        let(:ecp_eligibility) { build(:early_career_payments_eligibility, :ineligible) }
        let!(:ecp_claim) { create(:claim, :submittable, policy: EarlyCareerPayments, eligibility: ecp_eligibility) }
        let(:cc) { described_class.new(claims: Claim.where(id: [ecp_claim.id, lup_claim.id])) }
        let(:policy) { lup_claim.policy }

        before { cc.submit!(policy) }

        it "stores the policy option provided on submission just for the LUP policy" do
          policy_options_provided = [
            {"policy" => "LevellingUpPremiumPayments", "award_amount" => "2000.0"}
          ]

          expect(lup_claim.reload.policy_options_provided).to eq policy_options_provided
        end
      end

      context "when nil policy is supplied" do
        let(:policy) { nil }

        before { cc.submit!(policy) }

        it "submits the main claim" do
          expect(ecp_claim.reload).to be_submitted
        end
      end

      context "when a claim for the supplied policy is not found" do
        subject(:result) { cc.submit!(policy) }

        let(:policy) { "not_found" }

        it "raises an Exception" do
          expect { result }.to raise_error(NoMethodError)
        end
      end
    end
  end

  describe "#eligibility_status" do
    let(:claim1) { instance_double("Claim") }
    let(:claim2) { instance_double("Claim") }

    subject { described_class.new(claims: [claim1, claim2]).eligibility_status }

    context "any are :eligible_now (have :eligible_later and :eligible_now)" do
      before do
        allow(claim1).to receive_message_chain(:eligibility, :status).and_return(:eligible_later)
        allow(claim2).to receive_message_chain(:eligibility, :status).and_return(:eligible_now)
      end

      it { is_expected.to eq(:eligible_now) }
    end

    context "none are :eligible_now but any are :eligible_later" do
      before do
        allow(claim1).to receive_message_chain(:eligibility, :status).and_return(:ineligible)
        allow(claim2).to receive_message_chain(:eligibility, :status).and_return(:eligible_later)
      end

      it { is_expected.to eq(:eligible_later) }
    end

    context "all are :ineligible" do
      before do
        allow(claim1).to receive_message_chain(:eligibility, :status).and_return(:ineligible)
        allow(claim2).to receive_message_chain(:eligibility, :status).and_return(:ineligible)
      end

      it { is_expected.to eq(:ineligible) }
    end

    context "all are :undetermined" do
      before do
        allow(claim1).to receive_message_chain(:eligibility, :status).and_return(:undetermined)
        allow(claim2).to receive_message_chain(:eligibility, :status).and_return(:undetermined)
      end

      it { is_expected.to eq(:undetermined) }
    end
  end
end
