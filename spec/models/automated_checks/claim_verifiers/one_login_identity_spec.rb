require "rails_helper"

RSpec.describe AutomatedChecks::ClaimVerifiers::OneLoginIdentity do
  describe "#perform" do
    subject do
      described_class.new(claim:)
    end

    context "when identity_confirmed_with_onelogin? is false" do
      let(:claim) do
        create(
          :claim,
          identity_confirmed_with_onelogin: false
        )
      end

      it "creates a failed task with no_data reason" do
        expect {
          subject.perform
        }.to change(Task.where(passed: false, reason: "no_data"), :count).by(1)
      end
    end

    context "when identity_confirmed_with_onelogin is true" do
      let(:claim) do
        create(:claim, :submitted, :with_onelogin_idv_data)
      end

      it "creates a passed task" do
        expect {
          subject.perform
        }.to change(Task.passed_automatically, :count).by(1)
      end
    end
  end
end
