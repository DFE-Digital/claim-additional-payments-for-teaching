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
  end

  describe "#translate_response" do
    let(:saml_response) { Verify::FakeSso::IDENTITY_VERIFIED_SAML_RESPONSE }
    let(:request_id) { "THE_REQUEST_ID" }
    let(:level_of_assurance) { "LEVEL_1" }

    let!(:stubbed_translate_request) { stub_vsp_translate_response_request(translate_request_payload) }
    let(:translate_request_payload) { {"samlResponse" => saml_response, "requestId" => request_id, "levelOfAssurance" => level_of_assurance} }

    it "makes a POST request to the VSP to translate the SAML response and returns the result as a Hash" do
      response = Verify::ServiceProvider.new.translate_response(saml_response, request_id, level_of_assurance)

      expect(stubbed_translate_request).to have_been_requested
      expect(response).to eql(stubbed_vsp_translated_response)
    end
  end
end
