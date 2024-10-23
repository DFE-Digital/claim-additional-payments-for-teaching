require "rails_helper"

RSpec.describe OneTimePassword::Validator do
  subject { described_class.new(one_time_passcode, generated_at, secret:) }

  let(:secret) { ROTP::Base32.random }
  let!(:one_time_passcode) { OneTimePassword::Generator.new(secret:).code }
  let!(:generated_at) { Time.now }

  context "with a valid code" do
    it { is_expected.to be_valid }

    it "has no warning" do
      expect(subject.warning).to be_nil
    end

    context "memoization" do
      before do
        subject.warning
        allow(ROTP::TOTP).to receive(:new) { rotp }
      end

      let(:rotp) { instance_double ROTP::TOTP }

      it "memoizes the result of the passcode verification" do
        expect(rotp).not_to receive(:verify)
        subject.warning
      end
    end
  end

  context "with an empty code" do
    let(:one_time_passcode) { "" }

    it { is_expected.to_not be_valid }

    it "has the correct warning" do
      expect(subject.warning).to eq "Enter a passcode"
    end
  end

  context "with a nil code" do
    let(:one_time_passcode) { nil }

    it { is_expected.to_not be_valid }

    it "has the correct warning" do
      expect(subject.warning).to eq "Enter a passcode"
    end
  end

  context "with a code that is too short" do
    let(:one_time_passcode) { "12345" }

    it { is_expected.to_not be_valid }

    it "has the correct warning" do
      expect(subject.warning).to eq "Enter a valid passcode containing 6 digits"
    end
  end

  context "with a code that is the correct length, but wrong" do
    let(:one_time_passcode) { "000000" }

    it { is_expected.to_not be_valid }

    it "has the correct warning" do
      expect(subject.warning).to eq "Enter a valid passcode"
    end
  end

  context "with a code that has expired" do
    before { travel 20.minutes }

    it { is_expected.to_not be_valid }

    it "has the correct warning" do
      expect(subject.warning).to eq "Your passcode has expired, request a new one"
    end

    context "when generated_at is not specified" do
      subject { described_class.new(one_time_passcode, secret:) }

      it { is_expected.to_not be_valid }

      it "has the correct warning" do
        expect(subject.warning).to eq "Your passcode is not valid or has expired"
      end
    end
  end

  context "not specifying generated_at" do
    subject { described_class.new(one_time_passcode, secret:) }

    context "with a valid code" do
      it { is_expected.to be_valid }

      it "has no warning" do
        expect(subject.warning).to be_nil
      end
    end
  end

  context "specifying a secret" do
    let!(:one_time_passcode) { OneTimePassword::Generator.new(secret: secret).code }
    subject { described_class.new(one_time_passcode, secret: secret) }

    let(:secret) { "somesecretstring" }

    context "with a valid code" do
      it { is_expected.to be_valid }

      it "has no warning" do
        expect(subject.warning).to be_nil
      end
    end
  end
end
