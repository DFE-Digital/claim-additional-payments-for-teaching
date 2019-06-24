require "rails_helper"

RSpec.describe "GOV.UK Verify requests", type: :request do
  describe "verify/authentications/new" do
    before do
      stub_vsp_generate_request
      get new_verify_authentication_path
    end

    it "renders a form that will submit an authentication request to Verify" do
      expect(response.body).to include("action=\"#{stubbed_auth_request_response["ssoLocation"]}\"")
      expect(response.body).to include(stubbed_auth_request_response["samlRequest"])
    end

    it "stores the request_id in the user’s session" do
      expect(session[:verify_request_id]).to eql(stubbed_auth_request_response["requestId"])
    end
  end
end
