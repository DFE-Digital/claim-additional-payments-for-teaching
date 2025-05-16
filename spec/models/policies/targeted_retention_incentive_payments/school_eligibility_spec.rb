require "rails_helper"

RSpec.describe Policies::TargetedRetentionIncentivePayments::SchoolEligibility do
  let(:eligible_school) { build(:school, :targeted_retention_incentive_payments_eligible) }
  let(:ineligible_school) { build(:school, :targeted_retention_incentive_payments_ineligible) }

  before { create(:journey_configuration, :targeted_retention_incentive_payments) }

  describe ".new" do
    specify { expect { described_class.new(nil) }.to raise_error("nil school") }
  end

  describe "#eligible?" do
    context "eligible" do
      specify { expect(described_class.new(eligible_school)).to be_eligible }
    end

    context "ineligible" do
      specify { expect(described_class.new(ineligible_school)).to_not be_eligible }
    end
  end
end
