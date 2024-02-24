require "rails_helper"

RSpec.describe Claims::IttSubjectHelper do
  let(:ecp_trainee_teacher_eligibility) { build(:early_career_payments_eligibility, :trainee_teacher) }
  let(:lup_trainee_teacher_eligibility) { build(:levelling_up_premium_payments_eligibility, :trainee_teacher) }

  let(:ecp_trainee_teacher_claim) { build(:claim, :first_lup_claim_year, policy: Policies::EarlyCareerPayments, eligibility: ecp_trainee_teacher_eligibility) }
  let(:lup_trainee_teacher_claim) { build(:claim, :first_lup_claim_year, policy: LevellingUpPremiumPayments, eligibility: lup_trainee_teacher_eligibility) }

  describe "#subject_symbols" do
    context "trainee teacher" do
      subject { helper.subject_symbols(CurrentClaim.new(claims: [ecp_trainee_teacher_claim, lup_trainee_teacher_claim])) }

      it { is_expected.to contain_exactly(:chemistry, :computing, :mathematics, :physics) }
    end

    # this delegates to another class which checks more combinations
    context "non-trainee example" do
      let(:itt_year) { AcademicYear::Type.new.serialize(AcademicYear.new(2020)) }

      let(:eligible_ecp_eligibility) { build(:early_career_payments_eligibility, :eligible, itt_academic_year: itt_year) }
      let(:eligible_lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible, itt_academic_year: itt_year) }

      let(:eligible_ecp_claim) { build(:claim, :first_lup_claim_year, policy: Policies::EarlyCareerPayments, eligibility: eligible_ecp_eligibility) }
      let(:eligible_lup_claim) { build(:claim, :first_lup_claim_year, policy: LevellingUpPremiumPayments, eligibility: eligible_lup_eligibility) }

      subject { helper.subject_symbols(CurrentClaim.new(claims: [eligible_ecp_claim, eligible_lup_claim])) }

      it { is_expected.to contain_exactly(:chemistry, :computing, :foreign_languages, :mathematics, :physics) }
    end
  end

  describe "#subjects_to_sentence_for_hint_text" do
    let(:ecp_claim) { build(:claim, :first_lup_claim_year, policy: Policies::EarlyCareerPayments, eligibility: ecp_eligibility) }
    let(:lup_claim) { build(:claim, :first_lup_claim_year, policy: LevellingUpPremiumPayments, eligibility: lup_eligibility) }

    subject { helper.subjects_to_sentence_for_hint_text(CurrentClaim.new(claims: [ecp_claim, lup_claim])) }

    before { create(:journey_configuration, :additional_payments) }

    context "trainee teacher" do
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :trainee_teacher) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :trainee_teacher) }

      it { is_expected.to eq("chemistry, computing, mathematics or physics") }
    end

    context "ineligible for ECP" do
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :ineligible) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :undetermined) }

      it { is_expected.to eq("chemistry, computing, mathematics or physics") }
    end

    context "ineligible for LUP" do
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :undetermined) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :ineligible) }

      it { is_expected.to eq("chemistry, languages, mathematics or physics") }
    end

    context "ineligible for neither LUP nor ECP" do
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :undetermined) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :undetermined) }

      it { is_expected.to eq("chemistry, computing, languages, mathematics or physics") }
    end

    context "LUP eligible and ECP eligible_later" do
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :eligible_later) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible) }

      it { is_expected.to eq("chemistry, computing, mathematics or physics") }
    end

    context "LUP ineligible and ECP eligible_later" do
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :eligible_later) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :ineligible) }

      it { is_expected.to eq("chemistry, languages, mathematics or physics") }
    end
  end

  describe "#dqt_subjects_playback" do
    let(:dbl) { double(dqt_teacher_record: double(itt_subjects:)) }

    let(:itt_subjects) { ["test test", "Test McTest", "TEST"] }

    it "titleizes the subjects which are all lowercase and joins with commas" do
      expect(helper.dqt_subjects_playback(dbl)).to eq("Test Test, Test McTest, TEST")
    end
  end
end
