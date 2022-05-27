# frozen_string_literal: true

require "rails_helper"

RSpec.describe PolicyConfiguration do
  describe ".for" do
    it "returns the configuration for a given policy" do
      expect(described_class.for(StudentLoans)).to eq policy_configurations(:student_loans)
      expect(described_class.for(MathsAndPhysics)).to eq policy_configurations(:maths_and_physics)

      # Same PolicyConfiguration for ECP and LUP
      expect(described_class.for(EarlyCareerPayments)).to eq policy_configurations(:early_career_payments)
      expect(described_class.for(LevellingUpPremiumPayments)).to eq policy_configurations(:early_career_payments)
    end
  end

  describe ".for_routing_name" do
    it "returns the configuration for a given routing name" do
      expect(described_class.for_routing_name("student-loans")).to eq policy_configurations(:student_loans)
      expect(described_class.for_routing_name("maths-and-physics")).to eq policy_configurations(:maths_and_physics)

      # ECP and LUP use the same routing name and share the same PolicyConfiguration
      expect(described_class.for_routing_name("early-career-payments")).to eq policy_configurations(:early_career_payments)
    end
  end

  describe ".policy_for_routing_name" do
    it "returns the first policy for that routing name" do
      expect(described_class.policy_for_routing_name("student-loans")).to eq StudentLoans
      expect(described_class.policy_for_routing_name("maths-and-physics")).to eq MathsAndPhysics
      expect(described_class.policy_for_routing_name("early-career-payments")).to eq EarlyCareerPayments
    end
  end

  describe ".policies_for_routing_name" do
    it "returns the policies for that routing name" do
      expect(described_class.policies_for_routing_name("student-loans")).to eq [StudentLoans]
      expect(described_class.policies_for_routing_name("maths-and-physics")).to eq [MathsAndPhysics]
      expect(described_class.policies_for_routing_name("early-career-payments")).to eq [EarlyCareerPayments, LevellingUpPremiumPayments]
    end
  end

  describe ".view_paths" do
    it "returns any extra view paths" do
      expect(described_class.view_paths).to eq(["early_career_payments"])
    end
  end

  describe ".all_routing_names" do
    it "returns all the routing names" do
      expect(described_class.all_routing_names).to eq(["student-loans", "maths-and-physics", "early-career-payments"])
    end
  end

  describe ".all_policies" do
    specify { expect(described_class.all_policies).to contain_exactly(LevellingUpPremiumPayments, EarlyCareerPayments, MathsAndPhysics, StudentLoans) }
  end

  describe "#policies" do
    it "returns the policies" do
      expect(described_class.for(StudentLoans).policies).to eq [StudentLoans]
      expect(described_class.for(MathsAndPhysics).policies).to eq [MathsAndPhysics]
      expect(described_class.for(EarlyCareerPayments).policies).to eq [EarlyCareerPayments, LevellingUpPremiumPayments]
    end
  end

  describe "#routing_name" do
    it "returns routing for PolicyConfiguration" do
      expect(described_class.for(StudentLoans).routing_name).to eq "student-loans"
      expect(described_class.for(MathsAndPhysics).routing_name).to eq "maths-and-physics"

      # Same routing_name for ECP and LUP
      expect(described_class.for(EarlyCareerPayments).routing_name).to eq "early-career-payments"
      expect(described_class.for(LevellingUpPremiumPayments).routing_name).to eq "early-career-payments"
    end
  end

  describe "#early_career_payments?" do
    it "returns true" do
      expect(policy_configurations(:early_career_payments).early_career_payments?).to be true
    end

    it "returns false" do
      expect(policy_configurations(:student_loans).early_career_payments?).to be false
      expect(policy_configurations(:maths_and_physics).early_career_payments?).to be false
    end
  end

  it "validates academic years are formated like '2020/2021'" do
    expect(described_class.new(policy_types: [StudentLoans])).not_to be_valid
    expect(described_class.new(policy_types: [StudentLoans], current_academic_year: "2020-2021")).not_to be_valid
    expect(described_class.new(policy_types: [StudentLoans], current_academic_year: "2020/2021")).to be_valid
  end
end
