module DfeSignInHelpers
  # Stubs the DfE Sign-in OpenID response and the call to the DfE Sign-in API
  # that we use to determine the roles that the user is authorised with.
  def stub_dfe_sign_in_with_role(role_code)
    organisation_id = "1234"
    user_id = "123"

    mock_dfe_sign_in_auth_session(user_id, organisation_id)
    stub_dfe_sign_in_user_info_request(user_id, organisation_id, role_code)
  end

  def mock_dfe_sign_in_auth_session(user_id, organisation_id)
    OmniAuth.config.mock_auth[:dfe] = OmniAuth::AuthHash.new(dfe_sign_in_auth_hash(user_id, organisation_id))
  end

  def dfe_sign_in_auth_hash(user_id, organisation_id)
    {
      "provider" => :dfe,
      "uid" => user_id,
      "info" => {
        "name" => nil,
        "email" => "test-dfe-sign-in@host.tld",
        "nickname" => nil,
        "first_name" => nil,
        "last_name" => nil,
        "gender" => nil,
        "image" => nil,
        "phone" => nil,
        "urls" => {"website" => nil},
      },
      "credentials" => {
        "id_token" => "REDACTED",
        "token" => "REDACTED",
        "refresh_token" => nil,
        "expires_in" => 3600,
        "scope" => "openid email organisation",
      },
      "extra" => {
        "raw_info" => {
          "sub" => user_id,
          "email" => "test-dfe-sign-in@host.tld",
          "organisation" => {
            "id" => organisation_id,
            "name" => "Department for Education",
            "category" => {"id" => "002", "name" => "Local Authority"},
            "urn" => nil,
            "uid" => nil,
            "ukprn" => nil,
            "establishmentNumber" => "001",
            "status" => {
              "id" => 1,
              "name" => "Open",
            },
            "closedOn" => nil,
            "address" => nil,
            "telephone" => nil,
            "statutoryLowAge" => nil,
            "statutoryHighAge" => nil,
            "legacyId" => "1031237",
            "companyRegistrationNumber" => nil,
          },
        },
      },
    }
  end

  def stub_dfe_sign_in_user_info_request(user_id, organisation_id, role_code)
    api_client_id = DfeSignIn.configuration.client_id
    api_base_url = DfeSignIn.configuration.base_url
    api_response = {
      "userId" => user_id,
      "serviceId" => "XXXXXXX",
      "organisationId" => organisation_id,
      "roles" => [
        {
          "id" => "YYYYYYY",
          "name" => "Access to Teacher Payments",
          "code" => role_code,
          "numericId" => "162",
          "status" => {
            "id" => 1,
          },
        },
      ],
      "identifiers" => [
        {
          "key" => "groups",
          "value" => "teacher_payments_access",
        },
      ],
    }.to_json

    stub_request(:get, "#{api_base_url}/services/#{api_client_id}/organisations/#{organisation_id}/users/#{user_id}")
      .to_return(status: 200, body: api_response)
  end
end
