require "rails_helper"

RSpec.describe Policies::TargetedRetentionIncentivePayments do
  describe "#verifiers_for_claim" do
    context "when a 2025/2026 claim" do
      let(:claim) { Claim.new(academic_year: AcademicYear.new(2025)) }

      it "returns array of verifiers" do
        expect(described_class.verifiers_for_claim(claim).size).to eql(7)
      end
    end

    context "when a 2026/2027 claim" do
      let(:claim) { Claim.new(academic_year: AcademicYear.new(2026)) }

      it "returns empty array" do
        expect(described_class.verifiers_for_claim(claim)).to be_empty
      end
    end
  end
end
