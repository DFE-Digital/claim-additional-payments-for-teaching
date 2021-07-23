require "rails_helper"

module OrdnanceSurvey
  RSpec.describe Configuration::Client do
    subject(:client) { described_class.new }

    describe "#base_url" do
      it "returns nil" do
        expect(client.base_url).to eq(nil)
      end
    end

    describe "#params" do
      it "returns empty hash" do
        expect(client.params).to eq({})
      end
    end
  end
end
