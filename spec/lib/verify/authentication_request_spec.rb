require "rails_helper"

RSpec.describe Verify::AuthenticationRequest do
  it "can be initialised with authentication request parameters" do
    auth_request = Verify::AuthenticationRequest.new(
      saml_request: "SAML_REQ", request_id: "REQ_ID", sso_location: "SSO_LOC"
    )

    expect(auth_request.saml_request).to eq "SAML_REQ"
    expect(auth_request.request_id).to eq "REQ_ID"
    expect(auth_request.sso_location).to eq "SSO_LOC"
  end

  describe ".generate" do
    it "returns a new AuthenticationRequest with parameters acquired from the ServiceProvider" do
      stub_vsp_generate_request
      auth_request = Verify::AuthenticationRequest.generate

      expect(auth_request).to be_kind_of(Verify::AuthenticationRequest)
      expect(auth_request.saml_request).to eql(stubbed_auth_request_response["samlRequest"])
      expect(auth_request.request_id).to eql(stubbed_auth_request_response["requestId"])
      expect(auth_request.sso_location).to eql(stubbed_auth_request_response["ssoLocation"])
    end
  end
end
