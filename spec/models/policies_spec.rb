require "rails_helper"

RSpec.describe Policies, type: :model do
  describe "::POLICIES" do
    it do
      expect(described_class::POLICIES).to eq([
        StudentLoans,
        Policies::EarlyCareerPayments,
        LevellingUpPremiumPayments
      ])
    end
  end

  describe "::AMENDABLE_ELIGIBILITY_ATTRIBUTES" do
    it do
      expect(described_class::AMENDABLE_ELIGIBILITY_ATTRIBUTES).to eq([
        :student_loan_repayment_amount, :award_amount, :award_amount
      ])
    end
  end

  describe "::all" do
    it do
      expect(described_class.all).to eq(described_class::POLICIES)
    end
  end

  describe "::options_for_select" do
    it do
      expect(described_class.options_for_select).to eq([
        ["Student Loans", "student-loans"],
        ["Early-Career Payments", "early-career-payments"],
        ["Levelling Up Premium Payments", "levelling-up-premium-payments"]
      ])
    end
  end

  describe "::[]" do
    it do
      described_class.all.each do |policy|
        expect(described_class[policy.policy_type]).to eq(policy)
      end
    end
  end

  describe "::constantize" do
    [Policies::EarlyCareerPayments].each do |policy|
      context "when #{policy}" do
        it do
          expect(described_class.constantize(policy.to_s)).to eq(policy)
        end
      end
    end

    [StudentLoans, LevellingUpPremiumPayments].each do |policy|
      context "when #{policy}" do
        it do
          expect(described_class.constantize(policy.to_s)).to eq(policy)
        end
      end
    end
  end
end
