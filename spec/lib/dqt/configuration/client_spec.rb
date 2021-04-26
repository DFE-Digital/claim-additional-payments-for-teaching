require "rails_helper"

module Dqt
  RSpec.describe Configuration::Client do
    subject(:client) { described_class.new }

    describe "#headers" do
      it "returns empty hash" do
        expect(client.headers).to eq({})
      end
    end

    describe "#host" do
      it "returns nil" do
        expect(client.host).to eq(nil)
      end
    end

    describe "#params" do
      it "returns empty hash" do
        expect(client.params).to eq({})
      end
    end

    describe "#port" do
      it "returns nil" do
        expect(client.port).to eq(nil)
      end
    end
  end
end
