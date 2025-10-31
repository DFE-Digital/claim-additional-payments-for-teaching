require "rails_helper"

RSpec.describe Policies::EarlyYearsPayments do
  describe "::VERIFIERS" do
    it "does not talk to DQT" do
      expect(described_class::VERIFIERS).not_to include(AutomatedChecks::ClaimVerifiers::Identity)
    end
  end

  describe "#approvable?" do
    context "when employment task passed" do
      let(:claim) do
        create(
          :claim,
          policy: Policies::EarlyYearsPayments
        )
      end

      before do
        claim.tasks.create!(name: "employment", passed: true)
      end

      it "returns truthy" do
        expect(subject.approvable?(claim)).to be_truthy
      end
    end

    context "when employment task passed" do
      let(:claim) do
        create(
          :claim,
          policy: Policies::EarlyYearsPayments
        )
      end

      before do
        claim.tasks.create!(name: "employment", passed: false)
      end

      it "returns false" do
        expect(subject.approvable?(claim)).to be_falsey
      end
    end

    context "when no employment task persisted" do
      let(:claim) do
        create(
          :claim,
          policy: Policies::EarlyYearsPayments
        )
      end

      it "returns falsey" do
        expect(subject.approvable?(claim)).to be_falsey
      end
    end
  end

  describe "#decision_deadline_date" do
    let(:claim) do
      build(
        :claim,
        :eligible,
        policy: Policies::EarlyYearsPayments,
        eligibility_attributes: {
          start_date: Date.new(2025, 9, 1)
        }
      )
    end

    it "is 6 months + 19 weeks from when claimant submits their half" do
      expected = Date.new(2026, 7, 12)
      expect(described_class.decision_deadline_date(claim)).to eql(expected)
    end

    context "when claimant yet to complete their half" do
      let(:claim) { build(:claim, policy: Policies::EarlyYearsPayments) }

      it "returns nil" do
        expect(described_class.decision_deadline_date(claim)).to be_nil
      end
    end
  end

  describe ".payroll_file_name" do
    subject(:payroll_file_name) { described_class.payroll_file_name }
    it { is_expected.to eq("EYFinancialIncentive") }
  end
end
