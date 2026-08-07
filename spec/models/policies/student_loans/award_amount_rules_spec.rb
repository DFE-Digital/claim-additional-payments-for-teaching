# frozen_string_literal: true

require "rails_helper"

RSpec.describe Policies::StudentLoans::AwardAmountRules do
  # The rules are duck typed on whatever record owns the award amount, so they
  # keep working when award_amount moves from Eligibility onto Claim.
  let(:record) { build(:student_loans_eligibility) }

  def validate(context: nil)
    record.errors.clear
    described_class.new(record).validate(context:)
    record.errors[:award_amount]
  end

  describe "the monetary amount rule" do
    it "applies in every context" do
      record.award_amount = 100_000

      expect(validate).to include("Enter a valid monetary amount")
      expect(validate(context: :amendment)).to include("Enter a valid monetary amount")
    end

    it "rejects values that are not a monetary amount" do
      record.award_amount = "don’t know"
      expect(validate).to include("Enter a valid monetary amount")

      record.award_amount = "£1,234.56"
      expect(validate).to include("Enter a valid monetary amount")
    end

    it "rejects negative values" do
      record.award_amount = "-99"

      expect(validate).to include("Enter a valid monetary amount")
    end

    it "allows zero, nil and amounts up to the maximum" do
      record.award_amount = 0
      expect(validate).to be_empty

      record.award_amount = nil
      expect(validate).to be_empty

      record.award_amount = described_class::MAX_AWARD_AMOUNT
      expect(validate).to be_empty
    end
  end

  describe "the amended award range rule" do
    let(:message) { "Enter a positive amount up to £5,000.00 (inclusive)" }

    it "only applies on amendment" do
      record.award_amount = described_class::MAX_AMENDED_AWARD_AMOUNT + 1

      expect(validate).to be_empty
      expect(validate(context: :amendment)).to include(message)
    end

    it "allows amounts up to the maximum" do
      record.award_amount = described_class::MAX_AMENDED_AWARD_AMOUNT

      expect(validate(context: :amendment)).to be_empty
    end

    it "rejects zero" do
      record.award_amount = 0

      expect(validate(context: :amendment)).to include(message)
    end

    it "does not apply when the award amount is unchanged" do
      record = create(:student_loans_eligibility)
      record.update_column(:award_amount, described_class::MAX_AMENDED_AWARD_AMOUNT + 1)

      described_class.new(record.reload).validate(context: :amendment)

      expect(record.errors[:award_amount]).to be_empty
    end
  end
end
