require "rails_helper"
require "verify/service_provider"

RSpec.describe Verify::ServiceProvider do
  describe "#generate_request" do
    it "makes a POST request to the VSP for an authenticate request and returns the response as a Hash" do
      request_stub = stub_vsp_generate_request
      response = Verify::ServiceProvider.new.generate_request

      expect(request_stub).to have_been_requested
      expect(response["ssoLocation"]).to eql(stubbed_auth_request_response["ssoLocation"])
      expect(response["requestId"]).to eql(stubbed_auth_request_response["requestId"])
      expect(response["samlRequest"]).to eql(stubbed_auth_request_response["samlRequest"])
    end
  end
end
