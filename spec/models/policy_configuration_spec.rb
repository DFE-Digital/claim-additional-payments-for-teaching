# frozen_string_literal: true

require "rails_helper"

RSpec.describe PolicyConfiguration do
  describe "#for" do
    it "returns the configuration for a given policy" do
      expect(PolicyConfiguration.for(StudentLoans)).to eq policy_configurations(:student_loans)
      expect(PolicyConfiguration.for(MathsAndPhysics)).to eq policy_configurations(:maths_and_physics)
      expect(PolicyConfiguration.for(EarlyCareerPayments)).to eq policy_configurations(:early_career_payments)
    end
  end

  describe "#policy" do
    it "returns the policy class" do
      expect(PolicyConfiguration.new(policy_type: StudentLoans).policy).to eq(StudentLoans)
    end
  end

  it "validates academic years are formated like '2020/2021'" do
    expect(PolicyConfiguration.new(policy_type: StudentLoans)).not_to be_valid
    expect(PolicyConfiguration.new(policy_type: StudentLoans, current_academic_year: "2020-2021")).not_to be_valid
    expect(PolicyConfiguration.new(policy_type: StudentLoans, current_academic_year: "2020/2021")).to be_valid
  end
end
