require "rails_helper"

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

    it "raises Verify::ResponseError if an error response is received" do
      request_stub = stub_vsp_generate_request(stubbed_auth_request_error_response)

      expect {
        Verify::ServiceProvider.new.generate_request
      }.to raise_error(Verify::ResponseError)

      expect(request_stub).to have_been_requested
    end
  end

  describe "#translate_response" do
    let(:saml_response) { Verify::FakeSso::IDENTITY_VERIFIED_SAML_RESPONSE }
    let(:request_id) { "THE_REQUEST_ID" }
    let(:level_of_assurance) { "LEVEL_1" }
    let(:translate_request_payload) { {"samlResponse" => saml_response, "requestId" => request_id, "levelOfAssurance" => level_of_assurance} }

    it "makes a POST request to the VSP to translate the SAML response and returns the result as a Hash" do
      stubbed_translate_request = stub_vsp_translate_response_request("identity-verified", translate_request_payload)
      response = Verify::ServiceProvider.new.translate_response(saml_response, request_id, level_of_assurance)
      translated_response = JSON.parse(stubbed_vsp_translated_response("identity-verified"))

      expect(stubbed_translate_request).to have_been_requested
      expect(response).to eql(translated_response)
    end

    it "raises Verify::ResponseError if an error response is received" do
      stubbed_translate_request = stub_vsp_translate_response_request("error", translate_request_payload)

      expect {
        Verify::ServiceProvider.new.translate_response(saml_response, request_id, level_of_assurance)
      }.to raise_error(Verify::ResponseError)

      expect(stubbed_translate_request).to have_been_requested
    end
  end
end
