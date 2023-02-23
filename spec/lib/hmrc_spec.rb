require "rails_helper"

RSpec.describe Hmrc do
  describe ".client" do
    it "returns same Client instance" do
      expect(described_class.send(:client))
        .to be_an_instance_of(Hmrc::Client)
        .and equal(described_class.send(:client))
    end
  end

  describe ".configuration" do
    it "returns same Configuration instance" do
      expect(described_class.send(:configuration))
        .to be_an_instance_of(Hmrc::Configuration)
        .and equal(described_class.send(:configuration))
    end
  end

  describe ".configure" do
    it "yields current configuration" do
      block = proc { |config| expect(config).to equal(described_class.send(:configuration)) }

      described_class.send(
        :configure,
        &block
      )
    end
  end
end
