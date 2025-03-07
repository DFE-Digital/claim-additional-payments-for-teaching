require "rails_helper"

RSpec.describe FeatureFlag do
  describe "::enabled?" do
    context "when enabled" do
      subject { described_class.create!(name: "foo", enabled: true) }

      it "returns truthy with symbol" do
        expect(described_class.enabled?(subject.name.to_sym)).to be_truthy
      end

      it "returns truthy with string" do
        expect(described_class.enabled?(subject.name)).to be_truthy
      end
    end

    context "when not enabled" do
      subject { described_class.create!(name: "foo", enabled: false) }

      it "returns falsey" do
        expect(described_class.enabled?(subject.name)).to be_falsey
      end
    end

    context "when flag does not exist" do
      it "returns falsey" do
        expect(described_class.enabled?(:do_not_exist)).to be_falsey
      end
    end
  end
end
