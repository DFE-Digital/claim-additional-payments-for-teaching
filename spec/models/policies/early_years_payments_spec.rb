require "rails_helper"

RSpec.describe Policies::EarlyYearsPayments do
  describe "::VERIFIERS" do
    it "does not talk to DQT" do
      expect(described_class::VERIFIERS).not_to include(AutomatedChecks::ClaimVerifiers::Identity)
    end
  end
end
