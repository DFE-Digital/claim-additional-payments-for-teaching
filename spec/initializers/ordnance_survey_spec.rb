require "rails_helper"

RSpec.describe "OrdnanceSurvey initializer" do
  describe "OrdnanceSurvey.configuration.client.base_url" do
    it "returns string from env var" do
      expect(OrdnanceSurvey.configuration.client.base_url).to eq("https://api.os.uk")
    end
  end

  describe "OrdnanceSurvey.configuration.client.params" do
    it "returns hash from env var" do
      expect(OrdnanceSurvey.configuration.client.params).to eq({key: "api-key-value"})
    end
  end
end
