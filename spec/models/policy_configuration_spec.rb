# frozen_string_literal: true

require "rails_helper"

RSpec.describe PolicyConfiguration do
  describe "#for" do
    it "returns the configuration for a given policy" do
      expect(PolicyConfiguration.for(StudentLoans)).to eq policy_configurations(:student_loans)
      expect(PolicyConfiguration.for(MathsAndPhysics)).to eq policy_configurations(:maths_and_physics)
    end
  end

  describe "#policy" do
    it "returns the policy class" do
      expect(PolicyConfiguration.new(policy_type: StudentLoans).policy).to eq(StudentLoans)
    end
  end
end
