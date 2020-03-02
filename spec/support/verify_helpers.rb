module VerifyHelpers
  def stub_vsp_generate_request(expected_response = stubbed_auth_request_response)
    stub_request(:post, Verify::ServiceProvider.generate_request_url)
      .with(headers: {"Content-Type" => "application/json"})
      .to_return(status: 200, body: expected_response.to_json, headers: {})
  end

  def stubbed_auth_request_response
    {
      "samlRequest" => "PD94bWwg",
      "requestId" => "REQUEST_ID",
      "ssoLocation" => "/verify/fake_sso"
    }
  end

  def stubbed_auth_request_error_response
    {
      "code" => 422,
      "message" => "Some error message"
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
      "levelOfAssurance" => "LEVEL_2"
    }
  end

  def stubbed_vsp_translated_response(type)
    File.read(Rails.root.join("spec", "fixtures", "verify", "#{type}.json"))
  end

  def parsed_vsp_translated_response(type)
    JSON.parse(stubbed_vsp_translated_response(type))
  end

  # A sample parsed response from a successful GOV.UK Verify authentication
  # request.
  def sample_parsed_verify_response(overrides = {})
    attributes = {
      "firstNames" => [
        {"value" => "Isambard", "verified" => true}
      ],
      "middleNames" => [],
      "surnames" => [
        {"value" => "Brunel", "verified" => true}
      ],
      "datesOfBirth" => [
        {"value" => "1806-04-09", "verified" => true}
      ],
      "addresses" => [
        {"value" => {"lines" => ["Verified Street", "Verified Town"], "postCode" => "M12 345"}, "verified" => true}
      ]
    }.merge(overrides.deep_stringify_keys)

    {
      "scenario" => "IDENTITY_VERIFIED",
      "pid" => "5989a87f344bb79ee8d0f0532c0f716deb4f8d71e906b87b346b649c4ceb20c5",
      "levelOfAssurance" => "LEVEL_2",
      "attributes" => attributes
    }
  end
end
