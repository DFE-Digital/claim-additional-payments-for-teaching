require "rails_helper"

RSpec.describe DfeSignIn do
  describe "#configure" do
    it "should make configuration variables available globally" do
      expect(DfeSignIn.configuration.client_id).to eq(ENV["DFE_SIGN_IN_API_CLIENT_ID"])
      expect(DfeSignIn.configuration.secret).to eq(ENV["DFE_SIGN_IN_API_SECRET"])
      expect(DfeSignIn.configuration.base_url).to eq(ENV["DFE_SIGN_IN_API_ENDPOINT"])
    end
  end
end
