require "rails_helper"

RSpec.describe DfeSignIn do
  describe "#configure" do
    config = DfeSignIn.configuration_for_client_id(ENV.fetch("DFE_SIGN_IN_API_CLIENT_ID"))

    specify { expect(config.client_id).to eq(ENV["DFE_SIGN_IN_API_CLIENT_ID"]).and be_present }
    specify { expect(config.secret).to eq(ENV["DFE_SIGN_IN_API_SECRET"]).and be_present }
    specify { expect(config.base_url).to eq(ENV["DFE_SIGN_IN_API_ENDPOINT"]).and be_present }
  end
end
