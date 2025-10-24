require "rails_helper"

RSpec.describe Tasks::FeProviderVerificationV2Job do
  let(:claim) { create(:claim, :further_education, :submitted) }

  describe "#perform" do
    let(:mock_task) { instance_double(AutomatedChecks::ClaimVerifiers::ProviderVerificationV2, perform: true) }

    it "calls perform on the task" do
      allow(AutomatedChecks::ClaimVerifiers::ProviderVerificationV2).to receive(:new).with(claim:).and_return(mock_task)

      subject.perform(claim)

      expect(mock_task).to have_received(:perform)
    end
  end
end
