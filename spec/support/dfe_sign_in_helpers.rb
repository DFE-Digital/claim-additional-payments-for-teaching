module DfeSignInHelpers
  # Stubs the DfE Sign-in OpenID response and the call to the DfE Sign-in API
  # that we use to determine the roles that the user is authorised with.
  def stub_dfe_sign_in_with_role(role_code, user_id = "123", organisation_id = "1234")
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
    url = dfe_sign_in_user_info_url(user_id, organisation_id)
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

    stub_request(:get, url)
      .to_return(status: 200, body: api_response)
  end

  def stub_failed_dfe_sign_in_user_info_request(user_id, organisation_id)
    url = dfe_sign_in_user_info_url(user_id, organisation_id)
    api_response = {
      "error": "An error occurred",
    }.to_json

    stub_request(:get, url)
      .to_return(status: 500, body: api_response)
  end

  def stub_dfe_sign_in_user_list_request(number_of_pages: 1, page_number: nil)
    url = "#{DfeSignIn.configuration.base_url}/users"
    url = "#{url}?page=#{page_number}" if page_number

    response = {
      "users" => [
        {
          "organisation" => {
            "id" => "5b0e38fc-1db7-11ea-978f-2e728ce88125",
            "name" => "ACME Inc",
          },
          "userId" => "5b0e3686-1db7-11ea-978f-2e728ce88125",
          "email" => "alice@example.com",
          "familyName" => "Example",
          "givenName" => "Alice",
        },
        {
          "organisation" => {
            "id" => "5b0e3bcc-1db7-11ea-978f-2e728ce88125",
            "name" => "ACME Inc",
          },
          "userId" => "5b0e3a78-1db7-11ea-978f-2e728ce88125",
          "email" => "bob@example.com",
          "familyName" => "Example",
          "givenName" => "Bob",
        },
        {
          "organisation" => {
            "id" => "5b0e3bcc-1db7-11ea-978f-2e728ce88125",
            "name" => "ACME Inc",
          },
          "userId" => "5b0e3d20-1db7-11ea-978f-2e728ce88125",
          "email" => "eve@example.com",
          "familyName" => "Example",
          "givenName" => "Eve",
        },
      ],
      "numberOfRecords" => 3,
      "page" => 1,
      "numberOfPages" => number_of_pages,
    }.to_json

    stub_request(:get, url)
      .to_return(body: response, status: 200)
  end

  def dfe_sign_in_user_info_url(user_id, organisation_id)
    api_client_id = DfeSignIn.configuration.client_id
    api_base_url = DfeSignIn.configuration.base_url
    "#{api_base_url}/services/#{api_client_id}/organisations/#{organisation_id}/users/#{user_id}"
  end
end
