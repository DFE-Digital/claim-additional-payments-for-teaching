require "rails_helper"

RSpec.describe LevellingUpPremiumPayments::Eligibility, type: :model do
  subject { build(:levelling_up_premium_payments_eligibility) }

  describe "associations" do
    it { should have_one(:claim) }
    it { should belong_to(:current_school).class_name("School").optional(true) }
  end

  describe "#policy" do
    specify { expect(subject.policy).to eq(LevellingUpPremiumPayments) }
  end

  describe "#ineligible?" do
    specify { expect(subject).to respond_to(:ineligible?) }
  end

  describe "#award_amount" do
    it { should_not allow_values(0, nil).for(:award_amount).on(:amendment) }
    it { should validate_numericality_of(:award_amount).on(:amendment).is_greater_than(0).is_less_than_or_equal_to(3_000).with_message("Enter a positive amount up to £3,000.00 (inclusive)") }
  end
end
