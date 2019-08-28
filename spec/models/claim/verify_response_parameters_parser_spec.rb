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

  describe "#first_name" do
    it "returns a 'verified' value for 'firstNames'" do
      parser = Claim::VerifyResponseParametersParser.new(sample_response_parameters(firstNames: [{value: "Bob", verified: true}]))
      expect(parser.first_name).to eq "Bob"
    end

    it "returns the most recent 'verified' value for 'firstNames'" do
      changed_name_parameters = sample_response_parameters({
        firstNames: [
          {value: "Barbara", verified: true, from: "1991-12-12", to: "2018-08-08"},
          {value: "Bob", verified: true, from: "2018-08-09"},
        ],
      })
      parser = Claim::VerifyResponseParametersParser.new(changed_name_parameters)

      expect(parser.first_name).to eq "Bob"
    end

    it "returns the 'verified' value without a from/to date (this will be the most recent)" do
      changed_name_parameters = sample_response_parameters({
        firstNames: [
          {value: "Bob", verified: true},
          {value: "Barbara", verified: true, from: "1991-12-12", to: "2018-08-08"},
        ],
      })
      parser = Claim::VerifyResponseParametersParser.new(changed_name_parameters)

      expect(parser.first_name).to eq "Bob"
    end

    it "raises a MissingResponseAttribute error if there is no 'verified' value for 'firstNames'" do
      unverified_name_paramters = sample_response_parameters({
        firstNames: [value: "Fred", verified: false],
      })

      expect { Claim::VerifyResponseParametersParser.new(unverified_name_paramters).first_name }.to raise_exception(
        Claim::VerifyResponseParametersParser::MissingResponseAttribute, "No verified value found for firstNames"
      )
    end
  end

  describe "#surname" do
    it "returns a 'verified' value for 'surnames'" do
      parser = Claim::VerifyResponseParametersParser.new(sample_response_parameters(surnames: [{value: "Booker", verified: true}]))
      expect(parser.surname).to eq "Booker"
    end

    it "returns the most recent 'verified' value for 'surnames'" do
      changed_name_parameters = sample_response_parameters({
        surnames: [
          {value: "Franklin", verified: true, from: "1991-12-12", to: "2018-08-08"},
          {value: "Booker", verified: true, from: "2018-08-09"},
        ],
      })
      parser = Claim::VerifyResponseParametersParser.new(changed_name_parameters)

      expect(parser.surname).to eq "Booker"
    end

    it "returns the 'verified' value without a from/to date (assuming this will be the most recent)" do
      changed_name_parameters = sample_response_parameters({
        surnames: [
          {value: "Brooker", verified: false},
          {value: "Booker", verified: true},
          {value: "Franklin", verified: true, from: "1991-12-12", to: "2018-08-08"},
        ],
      })
      parser = Claim::VerifyResponseParametersParser.new(changed_name_parameters)

      expect(parser.surname).to eq "Booker"
    end

    it "raises a MissingResponseAttribute error if there is no 'verified' value for 'surnames'" do
      unverified_name_paramters = sample_response_parameters({
        surnames: [value: "Fred", verified: false],
      })

      expect { Claim::VerifyResponseParametersParser.new(unverified_name_paramters).surname }.to raise_exception(
        Claim::VerifyResponseParametersParser::MissingResponseAttribute, "No verified value found for surnames"
      )
    end
  end

  describe "#middle_name" do
    it "returns the most recent 'verified' value for 'middleNames'" do
      changed_name_parameters = sample_response_parameters({
        "middleNames": [
          {value: "Horacio", verified: true, from: "1991-12-12", to: "2018-08-08"},
          {value: "Buster", verified: true, from: "2018-08-09"},
        ],
      })
      parser = Claim::VerifyResponseParametersParser.new(changed_name_parameters)

      expect(parser.middle_name).to eq "Buster"
    end

    it "returns nil if there are no 'middleNames'" do
      parser = Claim::VerifyResponseParametersParser.new(sample_response_parameters(middleNames: []))
      expect(parser.middle_name).to be_nil
    end

    it "returns nil if there is no 'verified' value for 'middleNames'" do
      parser = Claim::VerifyResponseParametersParser.new(sample_response_parameters(middleNames: [{value: "Horacio", verified: false}]))
      expect(parser.middle_name).to be_nil
    end
  end

  describe "#full_name" do
    it "joins the first name and surname together" do
      parser = Claim::VerifyResponseParametersParser.new(sample_response_parameters)
      expect(parser.full_name).to eq "Isambard Brunel"
    end

    it "includes a middle name when present" do
      parser = Claim::VerifyResponseParametersParser.new(sample_response_parameters(middleNames: [{value: "Kingdom", verified: true}]))
      expect(parser.full_name).to eq "Isambard Kingdom Brunel"
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
