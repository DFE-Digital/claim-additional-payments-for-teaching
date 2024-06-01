require "rails_helper"

RSpec.describe CurrentClaim, type: :model do
  subject(:current_claim) { described_class.new(claims: claims, selected_policy: selected_policy) }

  let(:ecp_policy) { Policies::EarlyCareerPayments }
  let(:lup_policy) { Policies::LevellingUpPremiumPayments }
  let(:student_loans_policy) { Policies::StudentLoans }

  let(:school) { create(:school) }

  let(:ecp_claim) { build(:claim, academic_year: "2022/2023", policy: ecp_policy) }
  let(:lup_claim) { build(:claim, academic_year: "2022/2023", policy: lup_policy) }

  let(:student_loans_claim) { build(:claim, academic_year: "2022/2023", policy: student_loans_policy) }

  let(:claims) { [ecp_claim, lup_claim] }
  let(:selected_policy) { nil }

  describe "#attributes=" do
    let!(:first_claim) { current_claim.claims.first }
    let!(:second_claim) { current_claim.claims.last }

    subject(:set_attributes) do
      current_claim.attributes = {"eligibility_attributes" => {"current_school_id" => school.id}}
    end

    it "sets the attributes on both claims" do
      expect { set_attributes }
        .to change { first_claim.school&.id }.from(nil).to(school.id)
        .and change { second_claim.school&.id }.from(nil).to(school.id)
    end
  end

  describe "#save!" do
    before do
      current_claim.attributes = {"eligibility_attributes" => {"current_school_id" => school.id}}
      current_claim.save!
    end

    it "saves both claims" do
      expect(ecp_claim.reload.school.id).to eq(school.id)
      expect(lup_claim.reload.school.id).to eq(school.id)
    end
  end

  describe "#save" do
    subject(:save) { current_claim.save }

    context "when claim attributes are invalid" do
      let(:lup_claim) { build(:claim, academic_year: "2022/2023", policy: lup_policy, teacher_reference_number: "1") }

      it "calls save on both claims" do
        expect(lup_claim).to receive(:save)
        expect(ecp_claim).to receive(:save)

        save
      end

      it { is_expected.to be false }
    end

    context "when claim attributes are valid" do
      let(:lup_claim) { build(:claim, academic_year: "2022/2023", policy: lup_policy, teacher_reference_number: "1234567") }

      it "calls save on both claims" do
        expect(lup_claim).to receive(:save)
        expect(ecp_claim).to receive(:save)
        subject
      end

      it { is_expected.to be true }
    end
  end

  describe "#reset_dependent_answers" do
    subject(:reset_dependent_answers) { current_claim.reset_dependent_answers }

    it "calls reset reset_dependent_answers on both claims" do
      expect(ecp_claim).to receive(:reset_dependent_answers)
      expect(lup_claim).to receive(:reset_dependent_answers)

      reset_dependent_answers
    end
  end

  describe "#eligibility.reset_dependent_answers" do
    subject(:reset_eligibility_dependent_answers) { current_claim.reset_eligibility_dependent_answers }

    it "calls reset_dependent_answers on both claims' eligibility" do
      expect(ecp_claim.eligibility).to receive(:reset_dependent_answers)
      expect(lup_claim.eligibility).to receive(:reset_dependent_answers)

      reset_eligibility_dependent_answers
    end
  end

  describe "#for_policy" do
    subject(:for_policy) { current_claim.for_policy(policy) }

    context "student loans claim" do
      let(:policy) { student_loans_policy }
      let(:claims) { [student_loans_claim] }

      it "returns the single student loans claims" do
        is_expected.to eq(student_loans_claim)
      end
    end

    context "ECP/LUP multiple claims" do
      let(:claims) { [ecp_claim, lup_claim] }

      context "when passing ECP as policy" do
        let(:policy) { ecp_policy }

        it "returns the ECP claim" do
          is_expected.to eq(ecp_claim)
        end
      end

      context "when passing LUP as policy" do
        let(:policy) { lup_policy }

        it "returns the LUP claim" do
          is_expected.to eq(lup_claim)
        end
      end
    end
  end

  describe "#policies" do
    specify { expect(current_claim.policies).to contain_exactly(ecp_policy, lup_policy) }
  end

  describe "#main_claim" do
    subject(:main_claim) { current_claim.main_claim }

    context "student loans claim" do
      let(:policy) { student_loans_policy }
      let(:claims) { [student_loans_claim] }

      context "when no policy is selected" do
        let(:selected_policy) { nil }

        it "returns the single student loans" do
          is_expected.to eq(student_loans_claim)
        end
      end

      context "when student loans is selected as a policy" do
        let(:selected_policy) { student_loans_policy }

        it "returns the single student loans claim" do
          is_expected.to eq(student_loans_claim)
        end
      end
    end

    context "ECP/LUP multiple claims" do
      context "when no policy is selected" do
        let(:selected_policy) { nil }

        it "returns the ECP claim by default" do
          is_expected.to eq(ecp_claim)
        end
      end

      context "when ECP is selected a policy" do
        let(:selected_policy) { ecp_policy }

        it { is_expected.to eq(ecp_claim) }
      end

      context "when LUP is selected a policy" do
        let(:selected_policy) { lup_policy }

        it { is_expected.to eq(lup_claim) }
      end
    end

    context "no claims" do
      let(:claims) { [] }

      it { expect { main_claim }.to raise_error(described_class::UnselectablePolicyError) }
    end
  end

  describe "#persisted?" do
    subject { current_claim.persisted? }

    context "when all claims are persisted" do
      before do
        claims.each(&:save!)
      end

      it { is_expected.to eq(true) }
    end

    context "when one of the claims is not persisted" do
      before do
        allow(ecp_claim).to receive(:save).and_return(false)
        claims.each(&:save)
      end

      it { is_expected.to eq(false) }
    end
  end

  describe "#ineligible?" do
    subject { current_claim.ineligible? }

    let!(:journey_configuration_ecp_lupp) { create(:journey_configuration, :additional_payments) }

    let(:ecp_claim) { create(:claim, academic_year: "2022/2023", policy: ecp_policy, eligibility: ecp_eligibility) }
    let(:lup_claim) { create(:claim, academic_year: "2022/2023", policy: lup_policy, eligibility: lup_eligibility) }

    let(:ecp_eligibility) { build(:early_career_payments_eligibility, :eligible) }
    let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible) }

    context "when both claims are eligible" do
      it { is_expected.to be false }
    end

    context "when the ECP claim is ineligible" do
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :ineligible) }

      it { is_expected.to be false }
    end

    context "when the LUP claim is ineligible" do
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
    subject { current_claim.eligible_now? }

    let!(:journey_configuration) { create(:journey_configuration, :additional_payments) }

    let(:ecp_eligibility) { build(:early_career_payments_eligibility, :eligible) }
    let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible) }

    let(:ecp_claim) { create(:claim, policy: Policies::EarlyCareerPayments, eligibility: ecp_eligibility) }
    let(:lup_claim) { create(:claim, policy: Policies::LevellingUpPremiumPayments, eligibility: lup_eligibility) }

    context "when both claims are eligible" do
      it { is_expected.to be true }
    end

    context "when the ECP claim is ineligible" do
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :ineligible) }

      it { is_expected.to be true }
    end

    context "when the LUP claim is ineligible" do
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :ineligible) }

      it { is_expected.to be true }
    end

    context "when both claims are ineligible" do
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :ineligible) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :ineligible) }

      it { is_expected.to be false }
    end
  end

  describe "#eligible_now" do
    subject(:eligible_now) { current_claim.eligible_now }

    let!(:journey_configuration) { create(:journey_configuration, :additional_payments) }

    let(:ecp_eligibility) { build(:early_career_payments_eligibility, :ineligible) }
    let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible) }

    let(:ecp_claim) { create(:claim, policy: Policies::EarlyCareerPayments, eligibility: ecp_eligibility) }
    let(:lup_claim) { create(:claim, policy: Policies::LevellingUpPremiumPayments, eligibility: lup_eligibility) }

    context "when one claim is eligible and one is ineligible" do
      it "returns only the eligible claim" do
        is_expected.to contain_exactly(lup_claim)
      end
    end

    context "when both claims are eligible" do
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :eligible) }

      it "returns both claims" do
        is_expected.to contain_exactly(ecp_claim, lup_claim)
      end
    end

    context "when both claims are ineligible" do
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :ineligible) }

      it { is_expected.to be_empty }
    end
  end

  describe "#eligible_now_and_sorted" do
    subject(:eligible_now_and_sorted) { current_claim.eligible_now_and_sorted }

    let!(:journey_configuration) { create(:journey_configuration, :additional_payments) }

    let(:ecp_claim) { create(:claim, policy: Policies::EarlyCareerPayments, eligibility: ecp_eligibility) }
    let(:lup_claim) { create(:claim, policy: Policies::LevellingUpPremiumPayments, eligibility: lup_eligibility) }
    let(:ecp_eligibility) { build(:early_career_payments_eligibility, :eligible, award_amount: ecp_amount) }
    let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible, award_amount: lup_amount) }

    context "with identical award amounts" do
      let(:ecp_amount) { 2000.0 }
      let(:lup_amount) { ecp_amount }

      it "orders the claims by name" do
        is_expected.to eq([ecp_claim, lup_claim])
      end
    end

    context "with different award amounts" do
      let(:ecp_amount) { 1000.0 }
      let(:lup_amount) { 2000.0 }

      it "orders the claims by highest award amount" do
        is_expected.to eq([lup_claim, ecp_claim])
      end
    end

    context "with different award amounts other way around" do
      let(:ecp_amount) { 3000.0 }
      let(:lup_amount) { 2000.0 }

      it "orders the claims by highest award amount" do
        is_expected.to eq([ecp_claim, lup_claim])
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
