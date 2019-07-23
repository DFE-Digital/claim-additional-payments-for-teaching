require "rails_helper"

RSpec.describe DfeSignIn do
  describe "#configure" do
    before do
      DfeSignIn.configure do |config|
        config.client_id = 123
        config.secret = "sekrit"
      end
    end

    it "should make configuration variables available globally" do
      expect(DfeSignIn.configuration.client_id).to eq(123)
      expect(DfeSignIn.configuration.secret).to eq("sekrit")
    end
  end
end
