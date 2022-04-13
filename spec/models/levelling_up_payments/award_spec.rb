require "rails_helper"

RSpec.describe LevellingUpPayments::Award do
  let(:eligible_school) { double("School", lup_amount_in_pounds: 1_000) }
  let(:ineligible_school) { double("School", lup_amount_in_pounds: 0) }

  describe ".new" do
    specify { expect { described_class.new(nil) }.to raise_error("nil school") }
  end

  describe "#amount_in_pounds" do
    context "eligible" do
      specify { expect(described_class.new(eligible_school)).to have_award }
      specify { expect(described_class.new(eligible_school).amount_in_pounds).to be_positive }
    end

    context "ineligible" do
      specify { expect(described_class.new(ineligible_school)).to_not have_award }
      specify { expect(described_class.new(ineligible_school).amount_in_pounds).to be_zero }
    end
  end
end
