module DfeSignInHelpers
  # Stubs the DfE Sign-in OpenID response and the call to the DfE Sign-in API
  # that we use to determine the roles that the user is authorised with.
  def stub_dfe_sign_in_with_role(role_code, user_id = "123", organisation_id = "1234", user_type = "admin")
    mock_dfe_sign_in_auth_session(
      auth_hash: {
        uid: user_id,
        extra: {
          raw_info: {
            sub: user_id,
            organisation: {
              id: organisation_id
            }
          }
        }
      }
    )
    stub_dfe_sign_in_user_info_request(user_id, organisation_id, role_code, user_type:)
  end

  def mock_dfe_sign_in_auth_session(auth_hash: {}, provider: :dfe)
    OmniAuth.config.mock_auth[provider] = OmniAuth::AuthHash.new(dfe_sign_in_auth_hash(auth_hash))
  end

  def dfe_sign_in_auth_hash(attributes)
    {
      "provider" => :dfe,
      "uid" => "123",
      "info" => {
        "name" => nil,
        "email" => "test-dfe-sign-in@host.tld",
        "nickname" => nil,
        "first_name" => nil,
        "last_name" => nil,
        "gender" => nil,
        "image" => nil,
        "phone" => nil,
        "urls" => {"website" => nil}
      },
      "credentials" => {
        "id_token" => "REDACTED",
        "token" => "REDACTED",
        "refresh_token" => nil,
        "expires_in" => 3600,
        "scope" => "openid email organisation"
      },
      "extra" => {
        "raw_info" => {
          "sub" => "123",
          "email" => "test-dfe-sign-in@host.tld",
          "organisation" => {
            "id" => "1234",
            "name" => "Department for Education",
            "category" => {"id" => "002", "name" => "Local Authority"},
            "urn" => nil,
            "uid" => nil,
            "ukprn" => nil,
            "establishmentNumber" => "001",
            "status" => {
              "id" => 1,
              "name" => "Open"
            },
            "closedOn" => nil,
            "address" => nil,
            "telephone" => nil,
            "statutoryLowAge" => nil,
            "statutoryHighAge" => nil,
            "legacyId" => "1031237",
            "companyRegistrationNumber" => nil
          }
        }
      }
    }.deep_merge(attributes.deep_stringify_keys)
  end

  def stub_dfe_sign_in_user_info_request(user_id, organisation_id, role_code, user_type:, service_id: "XXXXXXX")
    url = dfe_sign_in_user_info_url(user_id, organisation_id, user_type)
    api_response = {
      "userId" => user_id,
      "serviceId" => "XXXXXXX",
      "organisationId" => organisation_id,
      "roles" => Array.wrap(role_code).map.each_with_index do |code, i|
        {
          "id" => "YYYYYYY",
          "name" => "Access to Teacher Payments",
          "code" => code,
          "numericId" => "162",
          "status" => {
            "id" => i + 1
          }
        }
      end,
      "identifiers" => [
        {
          "key" => "groups",
          "value" => "teacher_payments_access"
        }
      ]
    }.to_json

    stub_request(:get, url)
      .to_return(status: 200, body: api_response)
  end

  def stub_failed_dfe_sign_in_user_info_request(user_id, organisation_id, user_type:, status: 500)
    url = dfe_sign_in_user_info_url(user_id, organisation_id, user_type)
    api_response = {
      error: "An error occurred"
    }.to_json

    stub_request(:get, url)
      .to_return(status: status, body: api_response)
  end

  def stub_dfe_sign_in_user_list_request(number_of_pages: 1, page_number: nil)
    url = "#{DfeSignIn.configuration_for_client_id(ENV.fetch("DFE_SIGN_IN_API_CLIENT_ID")).base_url}/users"
    url = "#{url}?page=#{page_number}" if page_number

    response = {
      "users" => [
        {
          "organisation" => {
            "id" => "5b0e38fc-1db7-11ea-978f-2e728ce88125",
            "name" => "ACME Inc"
          },
          "userId" => "5b0e3686-1db7-11ea-978f-2e728ce88125",
          "email" => "alice@example.com",
          "familyName" => "Example",
          "givenName" => "Alice"
        },
        {
          "organisation" => {
            "id" => "5b0e3bcc-1db7-11ea-978f-2e728ce88125",
            "name" => "ACME Inc"
          },
          "userId" => "5409565d-5be6-4285-ba09-76fd431db0b5",
          "email" => "bob@example.com",
          "familyName" => "Example",
          "givenName" => "Bob"
        },
        {
          "organisation" => {
            "id" => "5b0e3bcc-1db7-11ea-978f-2e728ce88125",
            "name" => "ACME Inc"
          },
          "userId" => "25f0f85c-bfb7-4a21-aedc-1253370d04b0",
          "email" => "eve@example.com",
          "familyName" => "Example",
          "givenName" => "Eve"
        }
      ],
      "numberOfRecords" => 3,
      "page" => 1,
      "numberOfPages" => number_of_pages
    }.to_json

    stub_request(:get, url)
      .to_return(body: response, status: 200)
  end

  def dfe_sign_in_user_info_url(user_id, organisation_id, user_type)
    client_id = DfeSignIn::User.client_id_for_user_type(user_type)
    config = DfeSignIn.configuration_for_client_id(client_id)

    api_client_id = config.client_id
    api_base_url = config.base_url

    "#{api_base_url}/services/#{api_client_id}/organisations/#{organisation_id}/users/#{user_id}"
  end
end
