def stub_vsp_generate_request
  stub_request(:post, Verify::ServiceProvider.generate_request_url)
    .with(headers: {"Content-Type" => "application/json"})
    .to_return(status: 200, body: stubbed_auth_request_response.to_json, headers: {})
end

def stubbed_auth_request_response
  {
    "samlRequest" => "PD94bWwg",
    "requestId" => "REQUEST_ID",
    "ssoLocation" => "/verify/fake_sso",
  }
end

def stub_vsp_translate_response_request(expected_request_payload = example_vsp_translate_request_payload)
  stub_request(:post, Verify::ServiceProvider.translate_response_url)
    .with(body: expected_request_payload.to_json, headers: {"Content-Type" => "application/json"})
    .to_return(status: 200, body: stubbed_vsp_translated_response.to_json, headers: {})
end

def example_vsp_translate_request_payload
  {
    "samlResponse" => Verify::FakeSso::IDENTITY_VERIFIED_SAML_RESPONSE,
    "requestId" => "REQUEST_ID",
    "levelOfAssurance" => "LEVEL_2",
  }
end

def stubbed_vsp_translated_response
  {
    "scenario" => "IDENTITY_VERIFIED",
    "pid" => "etikgj3ewowe",
    "levelOfAssurance" => "LEVEL_2",
    "attributes" => {
      "firstNames" => [
        {
          "verified" => true,
          "from" => "2019-06-25",
          "to" => "2019-06-25",
          "value" => "Isambard",
          "nonLatinScriptValue" => "string",
        },
      ],
      "middleNames" => [
        {
          "verified" => true,
          "from" => "2019-06-25",
          "to" => "2019-06-25",
          "value" => "Kingdom",
          "nonLatinScriptValue" => "string",
        },
      ],
      "surnames" => [
        {
          "verified" => true,
          "from" => "2019-06-25",
          "to" => "2019-06-25",
          "value" => "Brunel",
          "nonLatinScriptValue" => "string",
        },
      ],
      "datesOfBirth" => [
        {
          "verified" => true,
          "from" => "1806-04-09",
          "to" => "1806-04-09",
          "value" => "1806-04-09",
        },
      ],
      "gender" => {
        "verified" => true,
        "value" => "MALE",
      },
      "addresses" => [
        {
          "verified" => true,
          "from" => "2019-06-25",
          "to" => "2019-06-25",
          "value" => {
            "lines" => [
              "Verified Street",
              "Verified Town",
              "Verified County",
            ],
            "postCode" => "M12 345",
          },
        },
      ],
    },
  }
end
