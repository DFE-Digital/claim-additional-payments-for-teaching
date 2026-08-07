# frozen_string_literal: true

require "rails_helper"

RSpec.describe Policies::TargetedRetentionIncentivePayments::AwardAmountRules do
  # The rules are duck typed on whatever record owns the award amount, so they
  # keep working when award_amount moves from Eligibility onto Claim.
  let(:record) { build(:targeted_retention_incentive_payments_eligibility) }
  let(:message) { "Enter a positive amount up to £3,000.00 (inclusive)" }

  before do
    create(:journey_configuration, :targeted_retention_incentive_payments)
    create(:targeted_retention_incentive_payments_award, award_amount: 3_000)
  end

  def validate(context: nil)
    record.errors.clear
    described_class.new(record).validate(context:)
    record.errors[:award_amount]
  end

  it "only applies on amendment" do
    record.award_amount = 3_001

    expect(validate).to be_empty
    expect(validate(context: :amendment)).to include(message)
  end

  it "bounds the award by the largest award for the academic year" do
    record.award_amount = 3_000
    expect(validate(context: :amendment)).to be_empty

    record.award_amount = 3_001
    expect(validate(context: :amendment)).to include(message)
  end

  it "rejects zero and nil" do
    record.award_amount = 0
    expect(validate(context: :amendment)).to include(message)

    record.award_amount = nil
    expect(validate(context: :amendment)).to include(message)
  end

  it "applies regardless of whether the award amount changed" do
    record = create(:targeted_retention_incentive_payments_eligibility)
    record.update_column(:award_amount, 3_001)

    described_class.new(record.reload).validate(context: :amendment)

    expect(record.errors[:award_amount]).to include(message)
  end
end
