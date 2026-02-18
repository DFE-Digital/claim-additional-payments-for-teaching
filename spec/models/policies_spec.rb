require "rails_helper"

RSpec.describe Policies, type: :model do
  describe "::POLICIES" do
    it do
      expect(described_class::POLICIES).to eq([
        Policies::StudentLoans,
        Policies::EarlyCareerPayments,
        Policies::TargetedRetentionIncentivePayments,
        Policies::InternationalRelocationPayments,
        Policies::FurtherEducationPayments,
        Policies::EarlyYearsPayments
      ])
    end
  end

  describe "::AMENDABLE_ELIGIBILITY_ATTRIBUTES" do
    it do
      expect(described_class::AMENDABLE_ELIGIBILITY_ATTRIBUTES.sort).to eq([
        :award_amount, :further_education_teaching_start_year, :teacher_reference_number
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
        ["School Targeted Retention Incentive", "targeted-retention-incentive-payments"],
        ["International Relocation Payments", "international-relocation-payments"],
        ["Further Education Targeted Retention Incentive", "further-education-payments"],
        ["Early Years Financial Incentive Payments", "early-years-payments"]
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
    [Policies::StudentLoans, Policies::EarlyCareerPayments, Policies::TargetedRetentionIncentivePayments].each do |policy|
      context "when #{policy}" do
        it do
          expect(described_class.constantize(policy.to_s)).to eq(policy)
        end
      end
    end
  end
end
