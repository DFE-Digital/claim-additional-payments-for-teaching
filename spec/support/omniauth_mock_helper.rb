module OmniauthMockHelper
  def set_mock_auth(trn)
    OmniAuth.config.mock_auth[:default] = OmniAuth::AuthHash.new(
      "extra" => {
        "raw_info" => {
          "trn" => trn
        }
      }
    )
    Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:default]
  end
end
