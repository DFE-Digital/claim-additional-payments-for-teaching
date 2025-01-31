require "rails_helper"

RSpec.describe Claims::IttSubjectHelper do
  before { create(:journey_configuration, :additional_payments, current_academic_year: AcademicYear.new(2023)) }

  let(:ecp_trainee_teacher_eligibility) { build(:early_career_payments_eligibility, :trainee_teacher) }
  let(:targeted_retention_incentive_trainee_teacher_eligibility) { build(:targeted_retention_incentive_payments_eligibility, :trainee_teacher) }

  let(:ecp_trainee_teacher_claim) { create(:claim, :first_targeted_retention_incentive_claim_year, policy: Policies::EarlyCareerPayments, eligibility: ecp_trainee_teacher_eligibility) }
  let(:targeted_retention_incentive_trainee_teacher_claim) { create(:claim, :first_targeted_retention_incentive_claim_year, policy: Policies::TargetedRetentionIncentivePayments, eligibility: targeted_retention_incentive_trainee_teacher_eligibility) }

  describe "#subjects_to_sentence_for_hint_text" do
    let(:ecp_claim) { create(:claim, :first_targeted_retention_incentive_claim_year, policy: Policies::EarlyCareerPayments, eligibility: ecp_eligibility) }
    let(:targeted_retention_incentive_claim) { create(:claim, :first_targeted_retention_incentive_claim_year, policy: Policies::TargetedRetentionIncentivePayments, eligibility: targeted_retention_incentive_eligibility) }
    let(:journey_session) do
      create(:additional_payments_session, answers: answers)
    end

    subject { helper.subjects_to_sentence_for_hint_text(journey_session.answers) }

    context "trainee teacher" do
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :trainee_teacher) }
      let(:targeted_retention_incentive_eligibility) { build(:targeted_retention_incentive_payments_eligibility, :trainee_teacher) }
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
      let(:targeted_retention_incentive_eligibility) { build(:targeted_retention_incentive_payments_eligibility, :undetermined) }
      let(:answers) do
        build(
          :additional_payments_answers,
          :ecp_ineligible,
          :targeted_retention_incentive_undetermined
        )
      end

      it { is_expected.to eq("chemistry, computing, mathematics or physics") }
    end

    context "ineligible for Targeted Retention Incentive" do
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :undetermined) }
      let(:targeted_retention_incentive_eligibility) { build(:targeted_retention_incentive_payments_eligibility, :ineligible) }
      let(:answers) do
        build(
          :additional_payments_answers,
          :targeted_retention_incentive_ineligible,
          :ecp_undetermined
        )
      end

      it { is_expected.to eq("chemistry, languages, mathematics or physics") }
    end

    context "ineligible for neither Targeted Retention Incentive nor ECP" do
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :undetermined) }
      let(:targeted_retention_incentive_eligibility) { build(:targeted_retention_incentive_payments_eligibility, :undetermined) }
      let(:answers) do
        build(
          :additional_payments_answers,
          :ecp_and_targeted_retention_incentive_undetermined
        )
      end

      it { is_expected.to eq("chemistry, computing, languages, mathematics or physics") }
    end

    context "Targeted Retention Incentive eligible and ECP eligible_later" do
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :eligible_later) }
      let(:targeted_retention_incentive_eligibility) { build(:targeted_retention_incentive_payments_eligibility, :eligible) }
      let(:answers) do
        build(
          :additional_payments_answers,
          :ecp_eligible_later,
          :targeted_retention_incentive_eligible
        )
      end

      it { is_expected.to eq("chemistry, computing, mathematics or physics") }
    end

    context "Targeted Retention Incentive ineligible and ECP eligible_later" do
      let(:ecp_eligibility) { build(:early_career_payments_eligibility, :eligible_later) }
      let(:targeted_retention_incentive_eligibility) { build(:targeted_retention_incentive_payments_eligibility, :ineligible) }

      let(:answers) do
        build(
          :additional_payments_answers,
          :targeted_retention_incentive_ineligible,
          :ecp_eligible_later,
          itt_academic_year: AcademicYear.new(2020)
        )
      end

      it { is_expected.to eq("chemistry, languages, mathematics or physics") }
    end
  end
end
