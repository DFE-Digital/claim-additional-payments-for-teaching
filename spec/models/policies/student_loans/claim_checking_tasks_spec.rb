# frozen_string_literal: true

require "rails_helper"

RSpec.describe Policies::StudentLoans::ClaimCheckingTasks do
  subject(:identity_status) { described_class.new(claim).identity_status }

  describe "#identity_status" do
    let(:claim) do
      build(
        :claim,
        policy: Policies::StudentLoans,
        tasks: claim_tasks
      )
    end

    context "when there is no identity_confirmation task" do
      let(:claim_tasks) { [] }

      it { is_expected.to eq("Unverified") }
    end

    context "when the task passed" do
      let(:claim_tasks) do
        [
          build(
            :task,
            claim_verifier_match: nil,
            name: "identity_confirmation",
            passed: true
          )
        ]
      end

      it { is_expected.to eq("Passed") }
    end

    context "when the task failed" do
      let(:claim_tasks) do
        [
          build(
            :task,
            claim_verifier_match: nil,
            name: "identity_confirmation",
            passed: false
          )
        ]
      end

      it { is_expected.to eq("Failed") }
    end

    context "when the task is incomplete with a full claim verifier match" do
      let(:claim_tasks) do
        [
          build(
            :task,
            claim_verifier_match: :all,
            name: "identity_confirmation",
            passed: nil
          )
        ]
      end

      it { is_expected.to eq("Full match") }
    end

    context "when the task is incomplete with a partial claim verifier match" do
      let(:claim_tasks) do
        [
          build(
            :task,
            claim_verifier_match: :any,
            name: "identity_confirmation",
            passed: nil
          )
        ]
      end

      it { is_expected.to eq("Partial match") }
    end

    context "when the task is incomplete with no claim verifier match" do
      let(:claim_tasks) do
        [
          build(
            :task,
            claim_verifier_match: :none,
            name: "identity_confirmation",
            passed: nil
          )
        ]
      end

      it { is_expected.to eq("No match") }
    end
  end
end
