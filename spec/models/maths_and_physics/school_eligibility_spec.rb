require "rails_helper"

RSpec.describe MathsAndPhysics::SchoolEligibility do
  subject(:eligibility) { described_class.new(school) }

  describe "#eligible_current_school?" do
    context "with a secondary school" do
      context "with an open, state funded secondary school in an eligible local authority district" do
        let(:school) { build(:school, :maths_and_physics_eligible) }
        it { is_expected.to be_eligible_current_school }
      end

      context "when closed" do
        let(:school) { build(:school, :maths_and_physics_eligible, :closed) }
        it { is_expected.not_to be_eligible_current_school }
      end

      context "when not in an eligible local authority district" do
        let(:school) { build(:school, :maths_and_physics_ineligible) }
        it { is_expected.not_to be_eligible_current_school }
      end

      context "when not state funded" do
        let(:school) { build(:school, :maths_and_physics_eligible, :not_state_funded) }
        it { is_expected.not_to be_eligible_current_school }
      end
    end

    context "with an explicitly eligible school in an ineligible local authority district" do
      context "if the school is otherwise eligible" do
        let(:school) { build(:school, :maths_and_physics_explicitly_eligible) }
        it { is_expected.to be_eligible_current_school }
      end

      context "when closed" do
        let(:school) { build(:school, :maths_and_physics_explicitly_eligible, :closed) }
        it { is_expected.not_to be_eligible_current_school }
      end

      context "when not state funded" do
        let(:school) { build(:school, :maths_and_physics_explicitly_eligible, :not_state_funded) }
        it { is_expected.not_to be_eligible_current_school }
      end
    end

    context "with a special school" do
      context "with an open, state funded secondary equivalent special school in an eligible local authority district" do
        let(:school) { build(:school, :maths_and_physics_eligible, :special_school) }
        it { is_expected.to be_eligible_current_school }
      end

      context "when closed" do
        let(:school) { build(:school, :maths_and_physics_eligible, :special_school, :closed) }
        it { is_expected.not_to be_eligible_current_school }
      end

      context "when not in an eligble local authority district" do
        let(:school) { build(:school, :maths_and_physics_ineligible, :special_school) }
        it { is_expected.not_to be_eligible_current_school }
      end

      context "when not state funded" do
        let(:school) { build(:school, :maths_and_physics_eligible, :special_school, :not_state_funded) }
        it { is_expected.not_to be_eligible_current_school }
      end

      context "when not secondary equivalent" do
        let(:school) { build(:school, :maths_and_physics_eligible, :special_school, :not_secondary_equivalent) }
        it { is_expected.not_to be_eligible_current_school }
      end
    end

    context "with alternative provision school" do
      context "with an open, state funded secondary equivalent alternative provision school in an eligible local authority district" do
        let(:school) { build(:school, :maths_and_physics_eligible, :alternative_provision) }
        it { is_expected.to be_eligible_current_school }
      end

      context "when closed" do
        let(:school) { build(:school, :maths_and_physics_eligible, :alternative_provision, :closed) }
        it { is_expected.not_to be_eligible_current_school }
      end

      context "when not in an eligble local authority district" do
        let(:school) { build(:school, :maths_and_physics_ineligible, :alternative_provision) }
        it { is_expected.not_to be_eligible_current_school }
      end

      context "when not secondary equivalent" do
        let(:school) { build(:school, :maths_and_physics_eligible, :alternative_provision, :not_secondary_equivalent) }
        it { is_expected.not_to be_eligible_current_school }
      end

      context "with a secure unit" do
        let(:school) { build(:school, :maths_and_physics_eligible, :secure_unit) }
        it { is_expected.to be_eligible_current_school }
      end
    end

    context "with a City Technology College (CTC)" do
      context "with an open, state funded secondary equivalent CTC in an eligible local authority district" do
        let(:school) { build(:school, :maths_and_physics_eligible, :city_technology_college) }
        it { is_expected.to be_eligible_current_school }
      end

      context "when closed" do
        let(:school) { build(:school, :maths_and_physics_eligible, :city_technology_college, :closed) }
        it { is_expected.not_to be_eligible_current_school }
      end

      context "when not in an eligible local authority district" do
        let(:school) { build(:school, :maths_and_physics_ineligible, :city_technology_college) }
        it { is_expected.not_to be_eligible_current_school }
      end

      context "when not secondary equivalent" do
        let(:school) { build(:school, :maths_and_physics_eligible, :city_technology_college, :not_secondary_equivalent) }
        it { is_expected.not_to be_eligible_current_school }
      end
    end
  end

  context "when it is not a secondary school" do
    context "returns false" do
      let(:school) { build(:school, :maths_and_physics_eligible, :not_secondary_equivalent) }
      it { is_expected.not_to be_eligible_current_school }
    end
  end
end
