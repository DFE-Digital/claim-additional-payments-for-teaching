require "rails_helper"

RSpec.describe Policies::EarlyYearsTeachersFinancialIncentivePayments do
  describe "::VERIFIERS" do
    it "includes the expected automated verifiers" do
      expect(described_class::VERIFIERS).to eq([
        AutomatedChecks::ClaimVerifiers::OneLoginIdentity,
        AutomatedChecks::ClaimVerifiers::StudentLoanPlan,
        AutomatedChecks::ClaimVerifiers::EyQualificationCheck
      ])
    end
  end

  describe "::ADMIN_DECISION_REJECTED_REASONS" do
    it "includes the expected rejected reasons" do
      expect(described_class::ADMIN_DECISION_REJECTED_REASONS).to eq([
        :no_response,
        :claimant_withdrew_application,
        :cant_verify_claimant_is_employed_at_setting,
        :duplicate_claim,
        :other_reason_only_used_in_exceptional_circumstances
      ])
    end
  end

  describe "#notify_reply_to_id" do
    it "returns the notify reply-to id" do
      expect(described_class.notify_reply_to_id).to eq("f7ad7769-b521-4b30-bd60-9779cfe12c63")
    end
  end

  describe "#auto_check_student_loan_plan_task?" do
    it "returns true" do
      expect(described_class.auto_check_student_loan_plan_task?).to be(true)
    end
  end

  describe "#decision_deadline_in_weeks" do
    it "returns 10 weeks" do
      expect(described_class.decision_deadline_in_weeks).to eq(10.weeks)
    end
  end

  describe "#hidden?" do
    subject(:hidden?) { described_class.hidden? }

    context "when in review environment" do
      before do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
        allow(ENV).to receive(:[]).with("ENVIRONMENT_NAME").and_return("review-123")
      end

      it { is_expected.to be(false) }
    end

    context "when in production but not review" do
      before do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
        allow(ENV).to receive(:[]).with("ENVIRONMENT_NAME").and_return("production")
      end

      it { is_expected.to be(true) }
    end

    context "when not in production" do
      before do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("test"))
      end

      it { is_expected.to be(false) }
    end
  end
end
