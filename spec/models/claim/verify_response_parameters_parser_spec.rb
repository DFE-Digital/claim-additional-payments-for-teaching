require "rails_helper"

RSpec.describe Claim::VerifyResponseParametersParser do
  describe "#gender" do
    it "returns :male when Verify reports 'gender' as 'MALE'" do
      parser = Claim::VerifyResponseParametersParser.new(sample_parsed_verify_response(gender: {value: "MALE", verified: true}))
      expect(parser.gender).to eq :male
    end

    it "returns :female when Verify reports 'gender' as 'FEMALE'" do
      parser = Claim::VerifyResponseParametersParser.new(sample_parsed_verify_response(gender: {value: "FEMALE", verified: true}))
      expect(parser.gender).to eq :female
    end

    it "returns nil when Verify reports 'gender' as neither 'MALE' nor 'FEMALE" do
      parser = Claim::VerifyResponseParametersParser.new(sample_parsed_verify_response(gender: {value: "OTHER", verified: true}))
      expect(parser.gender).to be_nil
    end

    it "returns a gender, even when the value is not 'verified'" do
      parser = Claim::VerifyResponseParametersParser.new(sample_parsed_verify_response(gender: {value: "MALE", verified: false}))
      expect(parser.gender).to eq :male
    end

    it "returns nil if the 'gender' is not reported at all" do
      parser = Claim::VerifyResponseParametersParser.new(sample_parsed_verify_response.except("gender"))
      expect(parser.gender).to be_nil
    end
  end

  describe "#date_of_birth" do
    it "returns the raw String value for the 'datesOfBirth' reported by Verify" do
      parser = Claim::VerifyResponseParametersParser.new(sample_parsed_verify_response(datesOfBirth: [{value: "1994-08-09"}]))
      expect(parser.date_of_birth).to eq "1994-08-09"
    end
  end

  describe "#first_name" do
    it "returns a 'verified' value for 'firstNames'" do
      parser = Claim::VerifyResponseParametersParser.new(sample_parsed_verify_response(firstNames: [{value: "Bob", verified: true}]))
      expect(parser.first_name).to eq "Bob"
    end

    it "returns the most recent 'verified' value for 'firstNames'" do
      changed_name_parameters = sample_parsed_verify_response({
        firstNames: [
          {value: "Barbara", verified: true, from: "1991-12-12", to: "2018-08-08"},
          {value: "Bob", verified: true, from: "2018-08-09"},
        ],
      })
      parser = Claim::VerifyResponseParametersParser.new(changed_name_parameters)

      expect(parser.first_name).to eq "Bob"
    end

    it "returns the 'verified' value without a from/to date (this will be the most recent)" do
      changed_name_parameters = sample_parsed_verify_response({
        firstNames: [
          {value: "Bob", verified: true},
          {value: "Barbara", verified: true, from: "1991-12-12", to: "2018-08-08"},
        ],
      })
      parser = Claim::VerifyResponseParametersParser.new(changed_name_parameters)

      expect(parser.first_name).to eq "Bob"
    end

    it "raises a MissingResponseAttribute error if there is no 'verified' value for 'firstNames'" do
      unverified_name_paramters = sample_parsed_verify_response({
        firstNames: [value: "Fred", verified: false],
      })

      expect { Claim::VerifyResponseParametersParser.new(unverified_name_paramters).first_name }.to raise_exception(
        Claim::VerifyResponseParametersParser::MissingResponseAttribute, "No verified value found for firstNames"
      )
    end
  end

  describe "#surname" do
    it "returns a 'verified' value for 'surnames'" do
      parser = Claim::VerifyResponseParametersParser.new(sample_parsed_verify_response(surnames: [{value: "Booker", verified: true}]))
      expect(parser.surname).to eq "Booker"
    end

    it "returns the most recent 'verified' value for 'surnames'" do
      changed_name_parameters = sample_parsed_verify_response({
        surnames: [
          {value: "Franklin", verified: true, from: "1991-12-12", to: "2018-08-08"},
          {value: "Booker", verified: true, from: "2018-08-09"},
        ],
      })
      parser = Claim::VerifyResponseParametersParser.new(changed_name_parameters)

      expect(parser.surname).to eq "Booker"
    end

    it "returns the 'verified' value without a from/to date (assuming this will be the most recent)" do
      changed_name_parameters = sample_parsed_verify_response({
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
      unverified_name_paramters = sample_parsed_verify_response({
        surnames: [value: "Fred", verified: false],
      })

      expect { Claim::VerifyResponseParametersParser.new(unverified_name_paramters).surname }.to raise_exception(
        Claim::VerifyResponseParametersParser::MissingResponseAttribute, "No verified value found for surnames"
      )
    end
  end

  describe "#middle_name" do
    it "returns the most recent 'verified' value for 'middleNames'" do
      changed_name_parameters = sample_parsed_verify_response({
        "middleNames": [
          {value: "Horacio", verified: true, from: "1991-12-12", to: "2018-08-08"},
          {value: "Buster", verified: true, from: "2018-08-09"},
        ],
      })
      parser = Claim::VerifyResponseParametersParser.new(changed_name_parameters)

      expect(parser.middle_name).to eq "Buster"
    end

    it "returns nil if there are no 'middleNames'" do
      parser = Claim::VerifyResponseParametersParser.new(sample_parsed_verify_response(middleNames: []))
      expect(parser.middle_name).to be_nil
    end

    it "returns nil if there is no 'verified' value for 'middleNames'" do
      parser = Claim::VerifyResponseParametersParser.new(sample_parsed_verify_response(middleNames: [{value: "Horacio", verified: false}]))
      expect(parser.middle_name).to be_nil
    end
  end

  describe "#postcode" do
    it "returns the 'postCode' from the most recent 'verified' address" do
      multi_address_parameters = sample_parsed_verify_response({
        addresses: [
          {
            value: {lines: ["Old Street", "Old Town"], postCode: "M21 1GP"},
            verified: true,
            from: "1991-12-12",
            to: "2018-08-08",
          },
          {
            value: {lines: ["Verified Street", "Verified Town"], postCode: "M1 7GL"},
            verified: true,
            from: "2018-08-08",
          },
        ],
      })
      parser = Claim::VerifyResponseParametersParser.new(multi_address_parameters)

      expect(parser.postcode).to eq "M1 7GL"
    end

    it "returns nil if there is no address" do
      parser = Claim::VerifyResponseParametersParser.new(sample_parsed_verify_response(addresses: []))

      expect(parser.postcode).to be_nil
    end
  end

  describe "the address_line_X methods" do
    it "returns address lines that are present from the most recent address" do
      short_address_parameters = sample_parsed_verify_response({addresses: [{value: {lines: ["Old Street", "Old Town"], postCode: "M21 1GP"}}]})
      parser = Claim::VerifyResponseParametersParser.new(short_address_parameters)
      expect(parser.address_line_1).to eq "Old Street"
      expect(parser.address_line_2).to eq "Old Town"
      expect(parser.address_line_3).to be_nil
      expect(parser.address_line_4).to be_nil

      full_address_parameters = sample_parsed_verify_response({
        addresses: [
          {
            value: {lines: ["Some house", "Unverified Street", "Unverified Town", "Unverified County"], postCode: "M1 7GL"},
            from: "2018-08-08",
          },
        ],
      })
      parser = Claim::VerifyResponseParametersParser.new(full_address_parameters)
      expect(parser.address_line_1).to eq "Some house"
      expect(parser.address_line_2).to eq "Unverified Street"
      expect(parser.address_line_3).to eq "Unverified Town"
      expect(parser.address_line_4).to eq "Unverified County"
    end

    it "returns nil if there are no 'addresses'" do
      parser = Claim::VerifyResponseParametersParser.new(sample_parsed_verify_response(addresses: []))

      expect(parser.address_line_1).to be_nil
      expect(parser.address_line_2).to be_nil
      expect(parser.address_line_3).to be_nil
      expect(parser.address_line_4).to be_nil
    end
  end

  describe "#attributes" do
    it "returns a compact attributes hash ready to be mass-assigned to a Claim record, including the keys of the verified fields and verify response" do
      parser = Claim::VerifyResponseParametersParser.new(sample_parsed_verify_response)
      expected_attributes = {
        first_name: "Isambard",
        surname: "Brunel",
        date_of_birth: "1806-04-09",
        address_line_1: "Verified Street",
        address_line_2: "Verified Town",
        postcode: "M12 345",
        verified_fields: %i[first_name surname date_of_birth address_line_1 address_line_2 postcode],
        verify_response: sample_parsed_verify_response,
      }

      expect(parser.attributes).to eq expected_attributes
    end
  end
end
