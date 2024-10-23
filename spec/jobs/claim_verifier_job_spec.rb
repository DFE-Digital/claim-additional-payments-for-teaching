require "rails_helper"

RSpec.describe ClaimVerifierJob do
  describe "#perform" do
    let(:claim) { build(:claim, dqt_teacher_status:) }
    let(:dbl) { double(find: mock_payload) }
    let(:verifier) { double(perform: true) }
    let(:mock_payload) { Dqt::Teacher.new({"mock" => "mock"}) }

    before do
      allow(Dqt::TeacherResource).to receive(:new).and_return(dbl)
      allow(AutomatedChecks::ClaimVerifier).to receive(:new).and_return(verifier)
    end

    context "when the claim has a DQT record payload" do
      let(:dqt_teacher_status) { {"test" => "test"} }

      it "does not request a new DQT payload" do
        expect(dbl).not_to receive(:find)
        described_class.new.perform(claim)
      end

      it "performs the verifier job" do
        expect(AutomatedChecks::ClaimVerifier).to receive(:new).with(claim:, dqt_teacher_status: Dqt::Teacher.new(dqt_teacher_status))
        described_class.new.perform(claim)
      end
    end

    context "when the claim has an empty DQT record payload" do
      let(:dqt_teacher_status) { {} }

      it "does requests a new DQT payload" do
        expect(dbl).to receive(:find)
        described_class.new.perform(claim)
      end

      it "performs the verifier job" do
        expect(AutomatedChecks::ClaimVerifier).to receive(:new).with(claim:, dqt_teacher_status: mock_payload)
        described_class.new.perform(claim)
      end

      context "when the claim does not have a TRN" do
        let(:claim) { build(:claim, policy: Policies::EarlyYearsPayments) }

        it "does not perform the verifier job" do
          expect(AutomatedChecks::ClaimVerifier).not_to receive(:new)
          described_class.new.perform(claim)
        end
      end
    end

    context "when the claim does not have a DQT record payload" do
      let(:dqt_teacher_status) { nil }

      it "does requests a new DQT payload" do
        expect(dbl).to receive(:find)
        described_class.new.perform(claim)
      end

      it "performs the verifier job" do
        expect(AutomatedChecks::ClaimVerifier).to receive(:new).with(claim:, dqt_teacher_status: mock_payload)
        described_class.new.perform(claim)
      end
    end
  end
end
