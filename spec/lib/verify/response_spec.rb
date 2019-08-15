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
      expect(subject.claim_parameters[:address_line_1]).to eq("Verified Building")
      expect(subject.claim_parameters[:address_line_2]).to eq("Verified Street")
      expect(subject.claim_parameters[:address_line_3]).to eq("Verified Town")
      expect(subject.claim_parameters[:address_line_4]).to eq("Verified County")
      expect(subject.claim_parameters[:postcode]).to eq("M12 345")
      expect(subject.claim_parameters[:date_of_birth]).to eq("1806-04-09")
      expect(subject.claim_parameters[:payroll_gender]).to eq(:male)
      expect(subject.claim_parameters[:verified_fields]).to match_array([
        :full_name,
        :address_line_1,
        :address_line_2,
        :address_line_3,
        :address_line_4,
        :postcode,
        :date_of_birth,
        :payroll_gender,
      ])
      expect(subject.claim_parameters[:verify_response]).to eq(response)
    end

    context "when the gender from Verify is female" do
      let(:response_filename) { "identity-verified-female.json" }

      it "returns the expected payroll_gender" do
        expect(subject.claim_parameters[:payroll_gender]).to eq(:female)
      end

      it "returns payroll_gender in the verified fields" do
        expect(subject.claim_parameters[:verified_fields]).to include(:payroll_gender)
      end
    end

    context "when the gender from Verify is not specified" do
      let(:response_filename) { "identity-verified-not-specified-gender.json" }

      it "returns nil for payroll_gender" do
        expect(subject.claim_parameters[:payroll_gender]).to eq(nil)
      end

      it "does not return payroll_gender in the verified fields" do
        expect(subject.claim_parameters[:verified_fields]).to_not include(:payroll_gender)
      end
    end

    context "when the gender from Verify is other" do
      let(:response_filename) { "identity-verified-other-gender.json" }

      it "returns nil for payroll_gender" do
        expect(subject.claim_parameters[:payroll_gender]).to eq(nil)
      end

      it "does not return payroll_gender in the verified fields" do
        expect(subject.claim_parameters[:verified_fields]).to_not include(:payroll_gender)
      end
    end

    context "when the address is missing (for EU citizens)" do
      let(:response_filename) { "identity-verified-no-address.json" }

      it "returns nil for address attributes" do
        expect(subject.claim_parameters[:address_line_1]).to eq(nil)
        expect(subject.claim_parameters[:address_line_2]).to eq(nil)
        expect(subject.claim_parameters[:address_line_3]).to eq(nil)
        expect(subject.claim_parameters[:postcode]).to eq(nil)
      end

      it "does not return any address attributes in the verified fields" do
        expect(subject.claim_parameters[:verified_fields]).to_not include(
          :address_line_1,
          :address_line_2,
          :address_line_3,
          :postcode
        )
      end
    end
  end

  context "with the minimum verified response" do
    let(:response_filename) { "identity-verified-minimum.json" }

    it "is verified" do
      expect(subject.verified?).to eq(true)
    end

    it "returns the expected verified parameters" do
      expect(subject.claim_parameters[:full_name]).to eq("Isambard Brunel")
      expect(subject.claim_parameters[:address_line_1]).to eq("Verified Street")
      expect(subject.claim_parameters[:address_line_2]).to eq("Verified Town")
      expect(subject.claim_parameters[:address_line_3]).to be_nil
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
