module OmniauthMockHelper
  def set_mock_auth(trn, opts = {}, phone_number: "01234567890")
    omniauth_data = if trn.nil?
      nil
    else
      OmniAuth::AuthHash.new(
        "extra" => {
          "raw_info" => {
            "trn" => trn,
            "birthdate" => "1940-01-01",
            "given_name" => "Kelsie",
            "family_name" => "Oberbrunner",
            "ni_number" => opts.key?(:nino) ? opts[:nino] : "AB123456C",
            "trn_match_ni_number" => "True",
            "email" => "kelsie.oberbrunner@example.com",
            "phone_number" => phone_number
          }
        }
      )
    end
    OmniAuth.config.mock_auth[:tid] = omniauth_data
    Rails.application.env_config["omniauth.auth"] = omniauth_data
  end
end
