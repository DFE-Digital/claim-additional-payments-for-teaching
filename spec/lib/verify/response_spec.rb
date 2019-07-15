require "rails_helper"

RSpec.describe Verify::Response, type: :model do
  subject { Verify::Response.new(response) }
  let(:response) { JSON.parse File.read(Rails.root.join("spec", "fixtures", "verify", response_filename)) }

  describe ".translate" do
    let(:saml_response) { example_vsp_translate_request_payload.fetch("samlResponse") }
    let(:request_id) { example_vsp_translate_request_payload.fetch("requestId") }
    let(:level_of_assurance) { example_vsp_translate_request_payload.fetch("levelOfAssurance") }

    it "returns a Verify::Response with the results of the translation from the ServiceProvider" do
      stub_vsp_translate_response_request

      verify_response = Verify::Response.translate(saml_response: saml_response, request_id: request_id, level_of_assurance: level_of_assurance)

      expect(verify_response).to be_kind_of(Verify::Response)
      expect(verify_response).to be_verified
      expect(verify_response.claim_parameters[:full_name]).to eq("Isambard Kingdom Brunel")
    end
  end

  context "with a verified response" do
    let(:response_filename) { "identity-verified.json" }

    it "is verified" do
      expect(subject.verified?).to eq(true)
    end

    it "returns the expected verified parameters" do
      expect(subject.claim_parameters[:full_name]).to eq("Isambard Kingdom Brunel")
      expect(subject.claim_parameters[:address_line_1]).to eq("Verified Street")
      expect(subject.claim_parameters[:address_line_2]).to eq("Verified Town")
      expect(subject.claim_parameters[:address_line_3]).to eq("Verified County")
      expect(subject.claim_parameters[:postcode]).to eq("M12 345")
      expect(subject.claim_parameters[:date_of_birth]).to eq("1806-04-09")
    end
  end

  context "with a cancelled response" do
    let(:response_filename) { "no-authentication.json" }

    it "is not verified" do
      expect(subject.verified?).to eq(false)
    end
  end

  context "with a failed response" do
    let(:response_filename) { "authentication-failed.json" }

    it "is not verified" do
      expect(subject.verified?).to eq(false)
    end
  end

  context "with an errored response" do
    let(:response_filename) { "error.json" }

    it "is not verified" do
      expect(subject.verified?).to eq(false)
    end
  end
end
