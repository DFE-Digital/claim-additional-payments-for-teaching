RSpec.shared_examples "eligibility_status" do |policy|
  describe "#status" do
    let(:trait_prefix) { {targeted_retention_incentive_payments: :targeted_retention_incentive}[policy] }

    let(:undetermined_trait) { :"#{trait_prefix}_undetermined" }
    let(:eligible_trait) { :"#{trait_prefix}_eligible" }
    let(:ineligible_trait) { :"#{trait_prefix}_ineligible" }
    let(:eligible_later_trait) { :"#{trait_prefix}_eligible_later" }
    let(:ineligible_school_trait) { :"#{trait_prefix}_ineligible_school" }

    context "ineligible" do
      let(:answers) { build(:targeted_retention_incentive_payments_answers, ineligible_trait) }

      it { is_expected.to eq(:ineligible) }
    end

    context "eligible now" do
      let(:answers) { build(:targeted_retention_incentive_payments_answers, eligible_trait) }

      it { is_expected.to eq(:eligible_now) }
    end

    context "eligible later but not now" do
      let(:answers) { build(:targeted_retention_incentive_payments_answers, eligible_later_trait) }

      it { is_expected.to eq(:eligible_later) }
    end

    context "undetermined" do
      let(:answers) { build(:targeted_retention_incentive_payments_answers, undetermined_trait) }

      it { is_expected.to eq(:undetermined) }
    end

    context "ineligible school" do
      let(:answers) { build(:targeted_retention_incentive_payments_answers, eligible_trait, ineligible_school_trait) }

      it { is_expected.to eq(:ineligible) }
    end

    context "short term supply teacher" do
      let(:answers) { build(:targeted_retention_incentive_payments_answers, eligible_trait, :short_term_supply_teacher) }

      it { is_expected.to eq(:ineligible) }
    end

    context "agency supply teacher" do
      let(:answers) { build(:targeted_retention_incentive_payments_answers, eligible_trait, :agency_supply_teacher) }

      it { is_expected.to eq(:ineligible) }
    end

    context "short term agency supply teacher" do
      let(:answers) { build(:targeted_retention_incentive_payments_answers, eligible_trait, :short_term_agency_supply_teacher) }

      it { is_expected.to eq(:ineligible) }
    end

    context "subject to formal performance action" do
      let(:answers) { build(:targeted_retention_incentive_payments_answers, eligible_trait, subject_to_formal_performance_action: true) }

      it { is_expected.to eq(:ineligible) }
    end

    context "subject to disciplinary action" do
      let(:answers) { build(:targeted_retention_incentive_payments_answers, eligible_trait, subject_to_disciplinary_action: true) }

      it { is_expected.to eq(:ineligible) }
    end

    context "insufficient teaching" do
      let(:answers) { build(:targeted_retention_incentive_payments_answers, eligible_trait, :insufficient_teaching) }

      it { is_expected.to eq(:ineligible) }
    end

    context "different routes to eligible now" do
      context "supply teacher status" do
        context "non supply teacher" do
          let(:answers) { build(:targeted_retention_incentive_payments_answers, eligible_trait, :not_a_supply_teacher) }

          it { is_expected.to eq(:eligible_now) }
        end

        context "long term directly employed supply teacher" do
          let(:answers) { build(:targeted_retention_incentive_payments_answers, eligible_trait, :long_term_directly_employed_supply_teacher) }

          it { is_expected.to eq(:eligible_now) }
        end
      end
    end
  end
end
