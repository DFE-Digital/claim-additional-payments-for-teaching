module OmniauthMockHelper
  def set_mock_auth(trn)
    omniauth_data = trn.nil? ? nil : OmniAuth::AuthHash.new(
      "extra" => {
        "raw_info" => {
          "trn" => trn,
          "email" => "test@gmail.com",
          "birthdate" => "1940-01-01",
          "given_name" => "Kelsie",
          "family_name" => "Oberbrunner",
          "ni_number" => "AB123456C",
          "trn_match_ni_number" => "true"
        }
      }
    )
    OmniAuth.config.mock_auth[:tid] = omniauth_data
    Rails.application.env_config["omniauth.auth"] = omniauth_data
  end
end
