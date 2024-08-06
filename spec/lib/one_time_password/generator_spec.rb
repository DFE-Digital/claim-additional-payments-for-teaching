require "rails_helper"

RSpec.describe OneTimePassword::Generator do
  describe "#code" do
    subject { described_class.new.code }

    let(:totp) { instance_double ROTP::TOTP, now: one_time_passcode }
    let(:one_time_passcode) { 123456 }

    before do
      allow(ROTP::TOTP).to receive(:new).and_return(totp)
    end

    it "generates a new code" do
      expect(subject).to eq one_time_passcode
    end
  end
end
