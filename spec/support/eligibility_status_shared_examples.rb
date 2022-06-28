RSpec.shared_examples "Eligibility status" do |eligibility_factory_symbol|
  describe "#status" do
    subject { eligibility.status }

    context "ineligible" do
      let(:eligibility) { build(eligibility_factory_symbol, :ineligible) }

      it { is_expected.to eq(:ineligible) }
    end

    context "eligible now" do
      let(:eligibility) { build(eligibility_factory_symbol, :eligible_now) }

      it { is_expected.to eq(:eligible_now) }
    end

    context "eligible later but not now" do
      let(:eligibility) { build(eligibility_factory_symbol, :eligible_later) }

      it { is_expected.to eq(:eligible_later) }
    end

    context "undetermined" do
      let(:eligibility) { build(eligibility_factory_symbol, :undetermined) }

      it { is_expected.to eq(:undetermined) }
    end

    context "ineligible attributes" do
      context "ineligible school" do
        let(:eligibility) { build(eligibility_factory_symbol, :eligible_now, :ineligible_school) }

        it { is_expected.to eq(:ineligible) }
      end

      context "short term supply teacher" do
        let(:eligibility) { build(eligibility_factory_symbol, :eligible_now, :short_term_supply_teacher) }

        it { is_expected.to eq(:ineligible) }
      end

      context "agency supply teacher" do
        let(:eligibility) { build(eligibility_factory_symbol, :eligible_now, :agency_supply_teacher) }

        it { is_expected.to eq(:ineligible) }
      end

      context "short term agency supply teacher" do
        let(:eligibility) { build(eligibility_factory_symbol, :eligible_now, :short_term_agency_supply_teacher) }

        it { is_expected.to eq(:ineligible) }
      end

      context "subject to formal performance action" do
        let(:eligibility) { build(eligibility_factory_symbol, :eligible_now, subject_to_formal_performance_action: true) }

        it { is_expected.to eq(:ineligible) }
      end

      context "subject to disciplinary action" do
        let(:eligibility) { build(eligibility_factory_symbol, :eligible_now, subject_to_disciplinary_action: true) }

        it { is_expected.to eq(:ineligible) }
      end

      context "insufficient teaching" do
        let(:eligibility) { build(eligibility_factory_symbol, :eligible_now, :insufficient_teaching) }

        it { is_expected.to eq(:ineligible) }
      end
    end

    context "different routes to eligible now" do
      context "supply teacher status" do
        context "non supply teacher" do
          let(:eligibility) { build(eligibility_factory_symbol, :eligible_now, :not_a_supply_teacher) }

          it { is_expected.to eq(:eligible_now) }
        end

        context "long term directly employed supply teacher" do
          let(:eligibility) { build(eligibility_factory_symbol, :eligible_now, :long_term_directly_employed_supply_teacher) }

          it { is_expected.to eq(:eligible_now) }
        end
      end
    end
  end

  describe "#eligible_next_year_too?" do
    subject { eligibility }

    context "eligible both now and later" do
      let(:eligibility) { build(eligibility_factory_symbol, :eligible_next_year_too) }

      specify { expect(subject.status).to eq(:eligible_now) }
      it { is_expected.to be_eligible_now }
      it { is_expected.to be_eligible_next_year_too }
    end
  end
end
