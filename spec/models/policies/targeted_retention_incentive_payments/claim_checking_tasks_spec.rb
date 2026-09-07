# frozen_string_literal: true

require "rails_helper"

RSpec.describe Policies::TargetedRetentionIncentivePayments::ClaimCheckingTasks do
  subject { described_class.new(claim) }

  describe "#identity_status" do
    let(:claim) do
      build(
        :claim,
        policy: Policies::TargetedRetentionIncentivePayments,
        tasks: claim_tasks
      )
    end

    context "when there is no identity_confirmation task" do
      let(:claim_tasks) { [] }

      it "returns Unverified" do
        expect(subject.identity_status).to eql("Unverified")
      end
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

      it "returns Passed" do
        expect(subject.identity_status).to eql("Passed")
      end
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

      it "returns Failed" do
        expect(subject.identity_status).to eql("Failed")
      end
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

      it "returns Full match" do
        expect(subject.identity_status).to eql("Full match")
      end
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

      it "returns Partial match" do
        expect(subject.identity_status).to eql("Partial match")
      end
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

      it "returns No match" do
        expect(subject.identity_status).to eql("No match")
      end
    end
  end

  describe "#applicable_task_names" do
    context "when 2025/2026 claim" do
      let(:claim) do
        build(
          :claim,
          policy: Policies::TargetedRetentionIncentivePayments,
          academic_year: AcademicYear.new(2025)
        )
      end

      it "returns corrects task names" do
        expected = [
          "identity_confirmation",
          "qualifications",
          "census_subjects_taught",
          "employment",
          "student_loan_plan",
          "payroll_details",
          "payroll_gender"
        ]

        expect(subject.applicable_task_names).to eql(expected)
      end
    end
  end
end
