module DfeSignInHelpers
  # Stubs the DfE Sign-in OpenID response and the call to the DfE Sign-in API
  # that we use to determine the roles that the user is authorised with.
  def stub_dfe_sign_in_with_role(role_code)
    organisation_id = "1234"

    OmniAuth.config.mock_auth[:dfe] = OmniAuth::AuthHash.new(
      "provider" => "dfe",
      "info" => {"email" => "test-dfe-sign-in@host.tld"},
      "extra" => {
        "raw_info" => {
          "organisation" => {
            "id" => organisation_id,
          },
        },
      }
    )

    api_client_id = DfeSignIn.configuration.client_id
    api_base_url = DfeSignIn.configuration.base_url
    api_response = {roles: [{code: role_code}]}.to_json

    stub_request(:get, "#{api_base_url}/services/#{api_client_id}/organisations/#{organisation_id}/users/")
      .to_return(status: 200, body: api_response)
  end
end
