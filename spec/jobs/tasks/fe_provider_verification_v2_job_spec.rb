require "rails_helper"

RSpec.describe Tasks::FeProviderVerificationV2Job do
  let(:claim) { create(:claim) }

  describe "#perform" do
    let(:mock_verifier) { instance_double(AutomatedChecks::ClaimVerifiers::ProviderVerificationV2, perform: true) }

    it "calls perform on the verifier" do
      allow(AutomatedChecks::ClaimVerifiers::ProviderVerificationV2).to receive(:new).with(claim:).and_return(mock_verifier)

      subject.perform(claim)

      expect(mock_verifier).to have_received(:perform)
    end
  end
end
