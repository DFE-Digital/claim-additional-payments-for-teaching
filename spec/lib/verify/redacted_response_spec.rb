require "rails_helper"

RSpec.describe Verify::RedactedResponse do
  it "redacts 'value' keys" do
    input = {"value" => "SECRET", "another-key" => "NOT SECRET"}
    expected_output = {"value" => "XXXXXX", "another-key" => "NOT SECRET"}

    expect(Verify::RedactedResponse.new(input).parameters).to eq expected_output
  end

  it "handles nested hashes" do
    input = {"attributes" => {"value" => "SECRET", "another-key" => "NOT SECRET"}}
    expected_output = {"attributes" => {"value" => "XXXXXX", "another-key" => "NOT SECRET"}}

    expect(Verify::RedactedResponse.new(input).parameters).to eq expected_output
  end

  it "handles values that are arrays" do
    input = {"firstNames" => [{"value" => "Bob", "verified" => true}, {"value" => "Booker", "verified" => true}]}
    expected_output = {"firstNames" => [{"value" => "XXX", "verified" => true}, {"value" => "XXXXXX", "verified" => true}]}

    expect(Verify::RedactedResponse.new(input).parameters).to eq expected_output
  end

  it "handles the sort of responses we get back from GOV.UK Verify" do
    input = parsed_vsp_translated_response("identity-verified")
    expected_output = {
      "scenario" => "IDENTITY_VERIFIED",
      "pid" => "5989a87f344bb79ee8d0f0532c0f716deb4f8d71e906b87b346b649c4ceb20c5",
      "levelOfAssurance" => "LEVEL_2",
      "attributes" => {
        "firstNames" => [
          {"value" => "XXXXXXXX", "verified" => true, "from" => "2019-06-25", "to" => "2019-06-30"},
          {"value" => "XXXXXX", "verified" => true, "from" => "2015-03-01", "to" => "2019-06-25"},
          {"value" => "XXX", "verified" => false, "from" => "2019-06-30"},
        ],
        "middleNames" => [
          {"value" => "XXXXXXX", "verified" => true, "from" => "2019-06-25", "to" => "2019-06-25"},
          {"value" => "XX", "verified" => false, "from" => "2019-06-25"},
        ],
        "surnames" => [
          {"value" => "XXXXXXX", "verified" => true, "from" => "2015-03-01", "to" => "2019-06-24"},
          {"value" => "XXXXXX", "verified" => true, "from" => "2019-06-25", "to" => "2019-06-25"},
          {"value" => "", "verified" => false, "from" => "2019-06-25"},
        ],
        "datesOfBirth" => [{"value" => "XXXXXXXXXX", "verified" => true, "from" => "1806-04-09"}],
        "gender" => {"value" => "XXXX", "verified" => true},
        "addresses" => [
          {
            "value" => {
              "lines" => ["XXXXXXXXXXXXXXXXX", "XXXXXXXXXXXXXXX", "XXXXXXXXXXXXX", "XXXXXXXXXXXXXXX"],
              "postCode" => "XXXXXXX",
            },
            "verified" => true,
            "from" => "2019-06-25",
            "to" => "2019-06-25",
          },
          {
            "value" => {
              "lines" => ["XXXXXXXXXXXXXXXXX", "XXXXXXXXXXXXXXX", "XXXXXXXXXXXXXXXXX"],
              "postCode" => "XXXXXXX",
            },
            "verified" => false,
            "from" => "2019-06-25",
          },
        ],
      },
    }

    expect(Verify::RedactedResponse.new(input).parameters).to eq expected_output
  end

  it "doesn't modify the original input" do
    input = parsed_vsp_translated_response("identity-verified")
    Verify::RedactedResponse.new(input).parameters

    expect(input).to eq parsed_vsp_translated_response("identity-verified")
  end
end
