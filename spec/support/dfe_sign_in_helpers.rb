module DfeSignInHelpers
  def stub_authorised_user!(organisation_id = "3bb6e3d7-64a9-42d8-b3f7-cf26101f3e82")
    stub_with_role_code(Admin::AuthController::DFE_SIGN_IN_ADMIN_ROLE_CODE, organisation_id)
  end

  def stub_unauthorised_user!(organisation_id = "3bb6e3d7-64a9-42d8-b3f7-cf26101f3e82")
    stub_with_role_code("some_code", organisation_id)
  end

  def stub_with_role_code(code, organisation_id)
    stub_url = "#{DfeSignIn.configuration.base_url}/services/#{DfeSignIn.configuration.client_id}/organisations/#{organisation_id}/users/"
    body = {
      roles: [
        {
          code: code,
        },
      ],
    }
    stub_request(:get, stub_url).to_return(status: 200, body: body.to_json)
  end
end
