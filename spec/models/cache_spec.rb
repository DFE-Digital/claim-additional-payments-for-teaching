require "rails_helper"

RSpec.describe Cache do
  describe "#expired?" do
    context "when expires_at not set" do
      subject { described_class.new(key: "foo", expires_at: nil) }

      it "returns falsey" do
        expect(subject).not_to be_expired
      end
    end

    context "when expired" do
      subject { described_class.new(key: "foo", expires_at: 1.day.ago) }

      it "returns truthy" do
        expect(subject).to be_expired
      end
    end

    context "when not expired" do
      subject { described_class.new(key: "foo", expires_at: 1.day.from_now) }

      it "returns falsey" do
        expect(subject).not_to be_expired
      end
    end
  end
end
