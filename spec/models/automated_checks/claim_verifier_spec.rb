require "rails_helper"

RSpec.describe AutomatedChecks::ClaimVerifier do
  subject(:claim_verifier) { described_class.new(**claim_verifier_args) }

  describe "#perform" do
    subject(:perform) { claim_verifier.perform }

    context "with two successful verifications" do
      let(:claim_verifier_args) do
        {
          claim: nil,
          dqt_teacher_statuses: nil,
          verifiers: [
            double("first verifier", perform: nil),
            double("second verifier", perform: Task.new),
            double("third verifier", perform: Task.new),
            double("third verifier", perform: Object.new)
          ]
        }
      end

      it { is_expected.to eq(2) }

      it "performs verifications" do
        perform

        claim_verifier_args[:verifiers].each do |verifier|
          expect(verifier).to have_received(:perform)
        end
      end
    end
  end
end
