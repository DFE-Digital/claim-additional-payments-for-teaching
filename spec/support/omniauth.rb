OmniAuth.config.test_mode = true
OmniAuth.config.path_prefix = "/admin/auth"
OmniAuth.config.mock_auth[:dfe] = OmniAuth::AuthHash.new(
  "provider" => "dfe",
  "info" => {"email" => "test@example.com"},
  "extra" => {
    "raw_info" => {
      "organisation" => {
        "id" => "3bb6e3d7-64a9-42d8-b3f7-cf26101f3e82",
      },
    },
  }
)
OmniAuth.config.on_failure = proc { |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}
