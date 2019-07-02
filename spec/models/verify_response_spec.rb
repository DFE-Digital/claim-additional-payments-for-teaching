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
  end
end
