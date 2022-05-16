require "rails_helper"

RSpec.describe LevellingUpPremiumPayments::Award do
  let(:eligible_school) { build(:school, :levelling_up_premium_payments_eligible) }
  let(:ineligible_school) { build(:school, :levelling_up_premium_payments_ineligible) }
  let(:not_found) { build(:school, :not_found_in_levelling_up_premium_payments_spreadsheet) }

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

  context "not found" do
    specify { expect(described_class.new(not_found)).to_not have_award }
    specify { expect(described_class.new(not_found).amount_in_pounds).to be_zero }
  end
end
