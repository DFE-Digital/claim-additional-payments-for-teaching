require "rails_helper"

RSpec.describe OneTimePassword::Generator do
  let(:totp) { instance_double ROTP::TOTP, now: one_time_passcode }
  let(:one_time_passcode) { 123456 }

  before do
    allow(ROTP::TOTP).to receive(:new).and_return(totp)
  end

  describe "#code" do
    subject { described_class.new.code }

    it "generates a new code" do
      expect(subject).to eq one_time_passcode
    end
  end

  context "specifying a secret" do
    subject { described_class.new(secret: secret).code }

    let(:secret) { "somesecret" }

    it "uses the secret" do
      expect(ROTP::TOTP).to receive(:new).with(ROTP::Base32.encode(secret), anything).and_return(totp)
      subject
    end

    it "generates a new code" do
      expect(subject).to eq one_time_passcode
    end
  end
end
