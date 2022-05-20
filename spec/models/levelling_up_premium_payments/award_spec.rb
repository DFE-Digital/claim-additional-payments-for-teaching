require "rails_helper"

RSpec.describe LevellingUpPremiumPayments::Award do
  let(:eligible_school) { build(:school, :levelling_up_premium_payments_eligible) }
  let(:ineligible_school) { build(:school, :levelling_up_premium_payments_ineligible) }

  describe ".new" do
    specify { expect { described_class.new(nil) }.to raise_error("nil school") }
  end

  context "eligible" do
    specify { expect(described_class.new(eligible_school)).to have_award }
    specify { expect(described_class.new(eligible_school).amount_in_pounds).to be_positive }
  end

  context "ineligible" do
    specify { expect(described_class.new(ineligible_school)).to_not have_award }
    specify { expect(described_class.new(ineligible_school).amount_in_pounds).to be_zero }
  end

  describe ".max" do
    specify { expect(described_class.max).to eq(3_000) }
  end

  describe "statistics" do
    subject { described_class.urn_to_award_amount_in_pounds }

    # *attempt* to check if the hash has been altered
    specify { expect(subject.values).to all be_positive }
    specify { expect(subject.values.sum).to eq(5_764_500) }
    specify { expect(subject.values.uniq).to contain_exactly(1_500, 2_000, 2_500, 3_000) }
    specify { expect(subject.count).to eq(2_655) }
    specify {
      expect(subject).not_to include(
        100182, # first ineligible school
        148866 # last ineligible school
      )
    }
    specify {
      expect(subject).to include(
        100006 => 2_000, # first eligible school (£2,000 award)
        100053 => 1_500, # first £1,500 award
        103760 => 2_500, # first £2,500 award
        103765 => 3_000, # first £3,000 award
        148965 => 3_000 # last eligible school
      )
    }
    specify { expect(subject).to be_frozen }
  end
end
