require "rails_helper"

RSpec.describe VerifyResponse, type: :model do
  subject { VerifyResponse.new(response) }
  let(:response) { JSON.parse File.read(Rails.root.join("spec", "fixtures", "verify", response_filename)) }

  context "with a valid response" do
    let(:response_filename) { "identity-verified.json" }

    it "is valid" do
      expect(subject.valid?).to eq(true)
    end

    it "returns the expected parameters" do
      expect(subject.claim_parameters[:full_name]).to eq("Isambard Kingdom Brunel")
      expect(subject.claim_parameters[:address_line_1]).to eq("Verified Street")
      expect(subject.claim_parameters[:address_line_2]).to eq("Verified Town")
      expect(subject.claim_parameters[:address_line_3]).to eq("Verified County")
      expect(subject.claim_parameters[:postcode]).to eq("M12 345")
      expect(subject.claim_parameters[:date_of_birth]).to eq("1806-04-09")
    end

    it "returns nil for an error" do
      expect(subject.error).to eq(nil)
    end
  end

  context "with a cancelled response" do
    let(:response_filename) { "no-authentication.json" }

    it "is not valid" do
      expect(subject.valid?).to eq(false)
    end

    it "returns the correct error" do
      expect(subject.error).to eq("no_authentication")
    end
  end

  context "with a failed response" do
    let(:response_filename) { "authentication-failed.json" }

    it "is not valid" do
      expect(subject.valid?).to eq(false)
    end

    it "returns the correct error" do
      expect(subject.error).to eq("authentication_failed")
    end
  end

  context "with an errored response" do
    let(:response_filename) { "error.json" }

    it "is not valid" do
      expect(subject.valid?).to eq(false)
    end

    it "returns the correct error" do
      expect(subject.error).to eq("error")
    end
  end
end
