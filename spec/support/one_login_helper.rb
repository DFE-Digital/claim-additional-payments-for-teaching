module OneLoginHelper
  def mock_one_login_auth
    hash = OmniAuth::AuthHash.new(
      uid: "12345",
      info: {
        email: "test@example.com"
      },
      extra: {
        raw_info: {}
      }
    )

    OmniAuth.config.mock_auth[:onelogin] = hash
    Rails.application.env_config["omniauth.auth"] = hash
  end

  def mock_one_login_idv
    hash = OmniAuth::AuthHash.new(
      uid: "12345",
      info: {
        email: ""
      },
      extra: {
        raw_info: {
          OmniauthCallbacksController::ONELOGIN_JWT_CORE_IDENTITY_HASH_KEY => "test"
        }
      }
    )

    OmniAuth.config.mock_auth[:onelogin] = hash
    Rails.application.env_config["omniauth.auth"] = hash
  end

  def mock_one_login_idv_with_return_codes
    hash = OmniAuth::AuthHash.new(
      uid: "12345",
      info: {
        email: ""
      },
      extra: {
        raw_info: {
          OmniauthCallbacksController::ONELOGIN_RETURN_CODE_HASH_KEY => [{"code" => "ABC"}]
        }
      }
    )

    OmniAuth.config.mock_auth[:onelogin] = hash
    Rails.application.env_config["omniauth.auth"] = hash
  end
end
