require "rails_helper"
require "verify/authentication_request"

RSpec.describe Verify::AuthenticationRequest do
  it "can be initialised with authentication request parameters" do
    auth_request = Verify::AuthenticationRequest.new(
      saml_request: "SAML_REQ", request_id: "REQ_ID", sso_location: "SSO_LOC"
    )

    expect(auth_request.saml_request).to eq "SAML_REQ"
    expect(auth_request.request_id).to eq "REQ_ID"
    expect(auth_request.sso_location).to eq "SSO_LOC"
  end
end
