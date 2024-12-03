require "rails_helper"

RSpec.describe Claims::IttSubjectHelper do
  before { create(:journey_configuration, :additional_payments, current_academic_year: AcademicYear.new(2023)) }

  let(:ecp_trainee_teacher_eligibility) { build(:early_career_payments_eligibility, :trainee_teacher) }
  let(:lup_trainee_teacher_eligibility) { build(:levelling_up_premium_payments_eligibility, :trainee_teacher) }

  let(:ecp_trainee_teacher_claim) { create(:claim, :first_lup_claim_year, policy: Policies::EarlyCareerPayments, eligibility: ecp_trainee_teacher_eligibility) }
  let(:lup_trainee_teacher_claim) { create(:claim, :first_lup_claim_year, policy: Policies::LevellingUpPremiumPayments, eligibility: lup_trainee_teacher_eligibility) }

  describe "#subjects_to_sentence_for_hint_text" do
    let(:ecp_claim) { create(:claim, :first_lup_claim_year, policy: Policies::EarlyCareerPayments, eligibility: ecp_eligibility) }
    let(:lup_claim) { create(:claim, :first_lup_claim_year, policy: Policies::LevellingUpPremiumPayments, eligibility: lup_eligibility) }
    let(:journey_session) do
      create(:additional_payments_session, answers: answers)
    end

    subject { helper.subjects_to_sentence_for_hint_text(journey_session.answers) }

    context "trainee teacher" do
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :trainee_teacher) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :trainee_teacher) }
      let(:answers) do
        build(
          :additional_payments_answers,
          :trainee_teacher
        )
      end

      it { is_expected.to eq("chemistry, computing, mathematics or physics") }
    end

    context "ineligible for ECP" do
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :ineligible) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :undetermined) }
      let(:answers) do
        build(
          :additional_payments_answers,
          :ecp_ineligible,
          :lup_undetermined
        )
      end

      it { is_expected.to eq("chemistry, computing, mathematics or physics") }
    end

    context "ineligible for LUP" do
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :undetermined) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :ineligible) }
      let(:answers) do
        build(
          :additional_payments_answers,
          :lup_ineligible,
          :ecp_undetermined
        )
      end

      it { is_expected.to eq("chemistry, languages, mathematics or physics") }
    end

    context "ineligible for neither LUP nor ECP" do
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :undetermined) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :undetermined) }
      let(:answers) do
        build(
          :additional_payments_answers,
          :ecp_and_lup_undetermined
        )
      end

      it { is_expected.to eq("chemistry, computing, languages, mathematics or physics") }
    end

    context "LUP eligible and ECP eligible_later" do
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :eligible_later) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :eligible) }
      let(:answers) do
        build(
          :additional_payments_answers,
          :ecp_eligible_later,
          :lup_eligible
        )
      end

      it { is_expected.to eq("chemistry, computing, mathematics or physics") }
    end

    context "LUP ineligible and ECP eligible_later" do
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :eligible_later) }
      let(:lup_eligibility) { build(:levelling_up_premium_payments_eligibility, :ineligible) }

      let(:answers) do
        build(
          :additional_payments_answers,
          :lup_ineligible,
          :ecp_eligible_later,
          itt_academic_year: AcademicYear.new(2020)
        )
      end

      it { is_expected.to eq("chemistry, languages, mathematics or physics") }
    end
  end
end
