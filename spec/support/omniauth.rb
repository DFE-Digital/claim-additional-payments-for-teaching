OmniAuth.config.test_mode = true
OmniAuth.config.path_prefix = "/admin/auth"
OmniAuth.config.mock_auth[:dfe] = OmniAuth::AuthHash.new(
  "provider" => "dfe",
  "info" => {"email" => "test@example.com"},
  "extra" => {
    "raw_info" => {
      "organisation" => {},
    },
  }
)
