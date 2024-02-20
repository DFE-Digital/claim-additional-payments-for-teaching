require "rails_helper"

RSpec.describe Policies::EarlyCareerPayments::SchoolEligibility do
  subject(:eligibility) { described_class.new(school) }

  describe "#eligible?" do
    context "with a secondary school" do
      context "with an open state funded secondary school in eligible local authority district" do
        let(:school) { build(:school, :early_career_payments_eligible) }

        it { is_expected.to be_eligible }
      end

      context "with a closed school" do
        let(:school) { build(:school, :early_career_payments_eligible, :closed) }

        it { is_expected.not_to be_eligible }
      end

      context "when the school is not state funded" do
        let(:school) { build(:school, :early_career_payments_eligible, :not_state_funded) }

        it { is_expected.not_to be_eligible }
      end
    end

    context "with an explicitly eligible school in an ineligible local authority district" do
      context "when the school is otherwise eligible" do
        let(:school) { build(:school, :early_career_payments_explicitly_eligible) }

        it { is_expected.to be_eligible }
      end

      context "with a closed school" do
        let(:school) { build(:school, :early_career_payments_explicitly_eligible, :closed) }

        it { is_expected.not_to be_eligible }
      end

      context "when the school is not state funded" do
        let(:school) { build(:school, :early_career_payments_explicitly_eligible, :not_state_funded) }

        it { is_expected.not_to be_eligible }
      end
    end

    context "with a special school" do
      context "with an open, state funded secondary equivalent special school in an eligible local authority district" do
        let(:school) { build(:school, :early_career_payments_eligible, :special_school) }

        it { is_expected.to be_eligible }
      end

      context "with a closed school" do
        let(:school) { build(:school, :early_career_payments_eligible, :closed, :special_school) }

        it { is_expected.not_to be_eligible }
      end

      context "when the school is not state funded" do
        let(:school) { build(:school, :early_career_payments_eligible, :special_school, :not_state_funded) }

        it { is_expected.not_to be_eligible }
      end

      context "when the school is not secondary equivalent" do
        let(:school) { build(:school, :early_career_payments_eligible, :special_school, :not_secondary_equivalent) }

        it { is_expected.not_to be_eligible }
      end
    end

    context "with alternative provision school" do
      context "with an open, state funded secondary equivalent alternative provision school in an eligible local authority district" do
        let(:school) { build(:school, :early_career_payments_eligible, :alternative_provision) }

        it { is_expected.to be_eligible }
      end

      context "when closed" do
        let(:school) { build(:school, :early_career_payments_eligible, :closed, :alternative_provision) }

        it { is_expected.not_to be_eligible }
      end

      context "when not secondary equivalent" do
        let(:school) { build(:school, :early_career_payments_eligible, :alternative_provision, :not_secondary_equivalent) }

        it { is_expected.not_to be_eligible }
      end

      context "with a secure unit" do
        let(:school) { build(:school, :early_career_payments_eligible, :secure_unit) }

        it { is_expected.to be_eligible }
      end
    end

    context "with a City Technology College (CTC)" do
      context "with an open, state funded secondary equivalent CTC in an eligible local authority district" do
        let(:school) { build(:school, :early_career_payments_eligible, :city_technology_college) }

        it { is_expected.to be_eligible }
      end

      context "when closed" do
        let(:school) { build(:school, :early_career_payments_eligible, :closed, :city_technology_college) }

        it { is_expected.not_to be_eligible }
      end

      context "when not secondary equivalent" do
        let(:school) { build(:school, :early_career_payments_eligible, :city_technology_college, :not_secondary_equivalent) }

        it { is_expected.not_to be_eligible }
      end
    end

    context "when it is not a secondary school" do
      let(:school) { build(:school, :early_career_payments_eligible, :not_secondary_equivalent) }

      it { is_expected.not_to be_eligible }
    end
  end

  describe "#eligible_uplift?" do
    context "when closed" do
      let(:school) { build(:school, :early_career_payments_uplifted, :closed) }

      it { is_expected.not_to be_eligible_uplift }
    end

    context "when the school is not in an uplifted local authority" do
      let(:school) { build(:school, :early_career_payments_eligible) }

      it { is_expected.not_to be_eligible_uplift }
    end

    context "when the school is in an uplifted local authority" do
      let(:school) { build(:school, :early_career_payments_uplifted) }

      it { is_expected.to be_eligible_uplift }
    end

    context "when has a close date in the future" do
      let(:school) { build(:school, :early_career_payments_uplifted, :closed, close_date: 10.days.from_now) }

      it { is_expected.to be_eligible_uplift }
    end
  end
end
