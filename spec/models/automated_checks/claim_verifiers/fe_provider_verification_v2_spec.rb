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
        expect(Task.last.data).to eq({"failed_checks" => ["no_continued_employment"]})
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

    context "when the claimant doesn't have a valid reason for not starting their qualification" do
      let(:eligibility) do
        build(
          :further_education_payments_eligibility,
          :eligible,
          :provider_verification_completed,
          provider_verification_not_started_qualification_reasons: ["no_valid_reason"]
        )
      end

      it "creates a failed task" do
        subject.perform

        task = claim.tasks.find_by!(name: "fe_provider_verification_v2")

        expect(task.failed?).to be true
        expect(task.manual?).to be false
        expect(task.data).to eq({"failed_checks" => ["no_valid_reason_for_not_starting_qualification"]})
      end
    end

    context "when the claimant has a valid reason for not starting their qualification" do
      let(:eligibility) do
        build(
          :further_education_payments_eligibility,
          :eligible,
          :provider_verification_completed,
          provider_verification_not_started_qualification_reasons: ["workload"]
        )
      end

      it "doesn't create a task" do
        expect { subject.perform }.not_to change { claim.tasks.count }
      end
    end
  end
end
