require "rails_helper"

RSpec.describe VerifyResponse, type: :model do
  include Rails.application.routes.url_helpers

  subject { VerifyResponse.new(response) }
  let(:response) { JSON.parse File.read(Rails.root.join("spec", "fixtures", "verify", response_filename)) }

  context "with a verified response" do
    let(:response_filename) { "identity-verified.json" }

    it "is verified" do
      expect(subject.verified?).to eq(true)
    end

    it "returns the expected parameters" do
      expect(subject.claim_parameters[:full_name]).to eq("Isambard Kingdom Brunel")
      expect(subject.claim_parameters[:address_line_1]).to eq("Verified Street")
      expect(subject.claim_parameters[:address_line_2]).to eq("Verified Town")
      expect(subject.claim_parameters[:address_line_3]).to eq("Verified County")
      expect(subject.claim_parameters[:postcode]).to eq("M12 345")
      expect(subject.claim_parameters[:date_of_birth]).to eq("1806-04-09")
    end

    it "returns nil for an error path" do
      expect(subject.error_path).to eq(nil)
    end
  end

  context "with a cancelled response" do
    let(:response_filename) { "no-authentication.json" }

    it "is not verified" do
      expect(subject.verified?).to eq(false)
    end

    it "returns the correct error path" do
      expect(subject.error_path).to eq(exited_verify_authentications_path)
    end
  end

  context "with a failed response" do
    let(:response_filename) { "authentication-failed.json" }

    it "is not verified" do
      expect(subject.verified?).to eq(false)
    end

    it "returns the correct error path" do
      expect(subject.error_path).to eq(failed_verify_authentications_path)
    end
  end

  context "with an errored response" do
    let(:response_filename) { "error.json" }

    it "is not verified" do
      expect(subject.verified?).to eq(false)
    end

    it "returns the correct error path" do
      expect(subject.error_path).to eq(error_verify_authentications_path)
    end
  end
end
