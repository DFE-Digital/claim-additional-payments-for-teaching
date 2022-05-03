require "rails_helper"

RSpec.describe DfeSignIn do
  describe "#configure" do
    specify { expect(DfeSignIn.configuration.client_id).to eq(ENV["DFE_SIGN_IN_API_CLIENT_ID"]).and be_present }
    specify { expect(DfeSignIn.configuration.secret).to eq(ENV["DFE_SIGN_IN_API_SECRET"]).and be_present }
    specify { expect(DfeSignIn.configuration.base_url).to eq(ENV["DFE_SIGN_IN_API_ENDPOINT"]).and be_present }
  end
end
