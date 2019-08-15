def stub_vsp_generate_request(expected_response = stubbed_auth_request_response)
  stub_request(:post, Verify::ServiceProvider.generate_request_url)
    .with(headers: {"Content-Type" => "application/json"})
    .to_return(status: 200, body: expected_response.to_json, headers: {})
end

def stubbed_auth_request_response
  {
    "samlRequest" => "PD94bWwg",
    "requestId" => "REQUEST_ID",
    "ssoLocation" => "/verify/fake_sso",
  }
end

def stubbed_auth_request_error_response
  {
    "code" => 422,
    "message" => "Some error message",
  }
end

def stub_vsp_translate_response_request(response_type = "identity-verified", expected_request_payload = example_vsp_translate_request_payload)
  stub_request(:post, Verify::ServiceProvider.translate_response_url)
    .with(body: expected_request_payload.to_json, headers: {"Content-Type" => "application/json"})
    .to_return(status: 200, body: stubbed_vsp_translated_response(response_type), headers: {})
end

def example_vsp_translate_request_payload
  {
    "samlResponse" => Verify::FakeSso::IDENTITY_VERIFIED_SAML_RESPONSE,
    "requestId" => "REQUEST_ID",
    "levelOfAssurance" => "LEVEL_2",
  }
end

def stubbed_vsp_translated_response(type)
  File.read(Rails.root.join("spec", "fixtures", "verify", "#{type}.json"))
end

def parsed_vsp_translated_response(type)
  JSON.parse(stubbed_vsp_translated_response(type))
end
