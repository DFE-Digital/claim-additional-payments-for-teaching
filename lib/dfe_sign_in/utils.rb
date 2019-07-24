module DfeSignIn
  module Utils
    def generate_jwt_token
      payload = {
        iss: DfeSignIn.configuration.client_id,
        exp: (Time.now.getlocal + 60).to_i,
        aud: "signin.education.gov.uk",
      }
      JWT.encode(payload, DfeSignIn.configuration.secret, "HS256")
    end
  end
end
