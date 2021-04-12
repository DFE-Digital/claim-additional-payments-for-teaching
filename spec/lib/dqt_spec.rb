require "rails_helper"

RSpec.describe Dqt do
  before do
    Dqt.configure do |config|
      config.client.host = config_args[:client][:host]
    end
  end

  let(:config_args) do
    {
      client: {
        host: "http://test"
      }
    }
  end

  describe "#configuration.client.host" do
    it "returns configured client host" do
      expect(described_class.configuration.client.host).to eq(config_args[:client][:host])
    end
  end
end
