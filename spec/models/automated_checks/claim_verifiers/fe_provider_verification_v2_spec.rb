require "rails_helper"

RSpec.describe AutomatedChecks::ClaimVerifiers::FeProviderVerificationV2 do
  subject { described_class.new(claim) }

  describe "#perform" do
    let(:claim) do
      create(
        :claim,
        :further_education,
        eligibility:
      )
    end

    context "when provider declares no for claimant continued employment" do
      let(:eligibility) do
        build(
          :further_education_payments_eligibility,
          provider_verification_continued_employment: false
        )
      end

      it "persists task as failed" do
        expect {
          subject.perform
        }.to change(Task, :count).by(1)

        expect(Task.last.passed?).to be_falsey
      end

      context "when task already persisted" do
        before do
          Task.create!(
            name: described_class::TASK_NAME,
            claim:,
            passed: true
          )
        end

        it "not create another task" do
          expect {
            subject.perform
          }.to not_change(Task, :count)
        end
      end
    end

    context "when provider declares yes for claimant continued employment" do
      let(:eligibility) do
        build(
          :further_education_payments_eligibility,
          provider_verification_continued_employment: true
        )
      end

      it "does not persist a task" do
        expect {
          subject.perform
        }.to not_change(Task, :count)
      end
    end
  end
end
