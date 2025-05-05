require "rails_helper"

RSpec.describe Policies::TargetedRetentionIncentivePayments::Eligibility, type: :model do
  subject { build(:targeted_retention_incentive_payments_eligibility) }

  describe "associations" do
    it { should have_one(:claim) }
    it { should belong_to(:current_school).class_name("School").optional(true) }
  end

  describe "#policy" do
    specify { expect(subject.policy).to eq(Policies::TargetedRetentionIncentivePayments) }
  end

  describe "#award_amount" do
    before do
      create(:journey_configuration, :additional_payments)
      create(:targeted_retention_incentive_payments_award, award_amount: 3_000)
    end

    it { should_not allow_values(0, nil).for(:award_amount).on(:amendment) }
    it { should validate_numericality_of(:award_amount).on(:amendment).is_greater_than(0).is_less_than_or_equal_to(3_000).with_message("Enter a positive amount up to £3,000.00 (inclusive)") }
  end

  describe "enum_methods" do
    context "when set by name" do
      it "sets the string column" do
        eligibility = create(
          :targeted_retention_incentive_payments_eligibility,
          qualification: "postgraduate_itt"
        )

        expect(eligibility.qualification_string).to eq("postgraduate_itt")
      end
    end

    context "when set by value" do
      it "sets the string column" do
        eligibility = create(
          :targeted_retention_incentive_payments_eligibility,
          qualification: 0
        )

        expect(eligibility.qualification_string).to eq("postgraduate_itt")
      end
    end
  end
end
