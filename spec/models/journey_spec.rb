require "rails_helper"

RSpec.describe Journey do
  describe ".all_policies" do
    specify { expect(described_class.all_policies).to contain_exactly(LevellingUpPremiumPayments, EarlyCareerPayments, MathsAndPhysics, StudentLoans) }
  end
end
