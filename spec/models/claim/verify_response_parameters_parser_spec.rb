require "rails_helper"

RSpec.describe Claim::VerifyResponseParametersParser do
  describe "#gender" do
    it "returns :male when Verify reports 'gender' as 'MALE'" do
      parser = Claim::VerifyResponseParametersParser.new(sample_response_parameters(gender: {value: "MALE", verified: true}))
      expect(parser.gender).to eq :male
    end

    it "returns :female when Verify reports 'gender' as 'FEMALE'" do
      parser = Claim::VerifyResponseParametersParser.new(sample_response_parameters(gender: {value: "FEMALE", verified: true}))
      expect(parser.gender).to eq :female
    end

    it "returns nil when Verify reports 'gender' as neither 'MALE' nor 'FEMALE" do
      parser = Claim::VerifyResponseParametersParser.new(sample_response_parameters(gender: {value: "OTHER", verified: true}))
      expect(parser.gender).to be_nil
    end

    it "returns a gender, even when the value is not 'verified'" do
      parser = Claim::VerifyResponseParametersParser.new(sample_response_parameters(gender: {value: "MALE", verified: false}))
      expect(parser.gender).to eq :male
    end

    it "returns nil if the 'gender' is not reported at all" do
      parser = Claim::VerifyResponseParametersParser.new(sample_response_parameters.except("gender"))
      expect(parser.gender).to be_nil
    end
  end

  describe "#date_of_birth" do
    it "returns the raw String value for the 'datesOfBirth' reported by Verify" do
      parser = Claim::VerifyResponseParametersParser.new(sample_response_parameters(datesOfBirth: [{value: "1994-08-09"}]))
      expect(parser.date_of_birth).to eq "1994-08-09"
    end
  end

  private

  def sample_response_parameters(overrides = {})
    attributes = {
      "firstNames" => [
        {"value" => "Isambard", "verified" => true},
      ],
      "middleNames" => [],
      "surnames" => [
        {"value" => "Brunel", "verified" => true},
      ],
      "datesOfBirth" => [
        {"value" => "1806-04-09", "verified" => true},
      ],
      "addresses" => [
        {"value" => {"lines" => ["Verified Street", "Verified Town"], "postCode" => "M12 345"}, "verified" => true},
      ],
    }.merge(overrides.deep_stringify_keys)

    {
      "scenario" => "IDENTITY_VERIFIED",
      "pid" => "5989a87f344bb79ee8d0f0532c0f716deb4f8d71e906b87b346b649c4ceb20c5",
      "levelOfAssurance" => "LEVEL_2",
      "attributes" => attributes,
    }
  end
end
