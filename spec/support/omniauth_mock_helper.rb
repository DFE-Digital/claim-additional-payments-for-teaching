module OmniauthMockHelper
  def set_mock_auth(trn, opts = {}, phone_number: "01234567890")
    omniauth_data = if trn.nil?
      nil
    else
      OmniAuth::AuthHash.new(
        "extra" => {
          "raw_info" => {
            "trn" => opts.key?(:returned_trn) ? opts[:returned_trn].to_s : trn.to_s,
            "birthdate" => opts.key?(:date_of_birth) ? opts[:date_of_birth].to_s : "1940-01-01",
            "given_name" => opts.fetch(:given_name, "Kelsie"),
            "family_name" => opts.fetch(:family_name, "Oberbrunner"),
            "ni_number" => opts.key?(:nino) ? opts[:nino].to_s : "AB123456C",
            "trn_match_ni_number" => "True",
            "email" => opts.fetch(:email, "kelsie.oberbrunner@example.com"),
            "phone_number" => phone_number.to_s
          }
        }
      )
    end
    OmniAuth.config.mock_auth[:tid] = omniauth_data
    Rails.application.env_config["omniauth.auth"] = omniauth_data
  end
end
