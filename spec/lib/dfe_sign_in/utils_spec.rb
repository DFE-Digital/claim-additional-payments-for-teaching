require "rails_helper"

RSpec.describe DfeSignIn::Utils do
  let(:dummy_class) { Class.new { extend DfeSignIn::Utils } }

  describe "generate_jwt_token" do
    around do |example|
      freeze_time { example.run }
    end

    let(:jwt_token) { dummy_class.generate_jwt_token }

    it "generates a JWT token" do
      expect(jwt_token).to_not eq(nil)
    end

    it "has the correct information" do
      payload = JWT.decode(jwt_token, DfeSignIn.configuration_for_client_id(ENV.fetch("DFE_SIGN_IN_API_CLIENT_ID")).secret, true, {algorithm: "HS256"})
      expect(payload.first).to eq({
        "iss" => DfeSignIn.configuration_for_client_id(ENV.fetch("DFE_SIGN_IN_API_CLIENT_ID")).client_id,
        "exp" => (Time.now.getlocal + 60).to_i,
        "aud" => "signin.education.gov.uk"
      })
      expect(payload.last).to eq({
        "alg" => "HS256"
      })
    end
  end
end
