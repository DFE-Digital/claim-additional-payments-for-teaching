# frozen_string_literal: true

require "rails_helper"

RSpec.describe PolicyConfiguration do
  describe "#for" do
    it "returns the configuration for a given policy" do
      expect(PolicyConfiguration.for(StudentLoans)).to eq policy_configurations(:student_loans)
      expect(PolicyConfiguration.for(MathsAndPhysics)).to eq policy_configurations(:maths_and_physics)

      # Same PolicyConfiguration for ECP and LUP
      expect(PolicyConfiguration.for(EarlyCareerPayments)).to eq policy_configurations(:early_career_payments)
      expect(PolicyConfiguration.for(LevellingUpPremiumPayments)).to eq policy_configurations(:early_career_payments)
    end
  end

  it "validates academic years are formated like '2020/2021'" do
    expect(PolicyConfiguration.new(policy_types: [StudentLoans])).not_to be_valid
    expect(PolicyConfiguration.new(policy_types: [StudentLoans], current_academic_year: "2020-2021")).not_to be_valid
    expect(PolicyConfiguration.new(policy_types: [StudentLoans], current_academic_year: "2020/2021")).to be_valid
  end

  describe "#routing_name" do
    it "returns routing for PolicyConfiguration" do
      expect(PolicyConfiguration.for(StudentLoans).routing_name).to eq "student-loans"
      expect(PolicyConfiguration.for(MathsAndPhysics).routing_name).to eq "maths-and-physics"

      # Same routing_name for ECP and LUP
      expect(PolicyConfiguration.for(EarlyCareerPayments).routing_name).to eq "early-career-payments"
      expect(PolicyConfiguration.for(LevellingUpPremiumPayments).routing_name).to eq "early-career-payments"
    end
  end
end
