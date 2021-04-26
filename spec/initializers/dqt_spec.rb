require "rails_helper"

RSpec.describe "DQT initializer" do
  describe "Dqt.configuration.client.headers" do
    it "returns hash from env var" do
      expect(Dqt.configuration.client.headers).to eq({header: "value"})
    end
  end

  describe "Dqt.configuration.client.host" do
    it "returns string from env var" do
      expect(Dqt.configuration.client.host).to eq("http://dqt.com")
    end
  end

  describe "Dqt.configuration.client.params" do
    it "returns hash from env var" do
      expect(Dqt.configuration.client.params).to eq({param: "value"})
    end
  end

  describe "Dqt.configuration.client.port" do
    it "returns integer from env var" do
      expect(Dqt.configuration.client.port).to eq(13)
    end
  end
end
