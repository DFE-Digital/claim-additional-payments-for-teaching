require "rails_helper"

RSpec.describe DfeSignIn::Utils do
  let(:dummy_class) { Class.new { extend DfeSignIn::Utils } }

  describe "generate_jwt_token" do
    before { freeze_time }
    after { travel_back }

    let(:jwt_token) { dummy_class.generate_jwt_token }

    it "generates a JWT token" do
      expect(jwt_token).to_not eq(nil)
    end

    it "has the correct information" do
      payload = JWT.decode(jwt_token, DfeSignIn.configuration.secret, true, {algorithm: "HS256"})
      expect(payload.first).to eq({
        "iss" => DfeSignIn.configuration.client_id,
        "exp" => (Time.now.getlocal + 60).to_i,
        "aud" => "signin.education.gov.uk",
      })
      expect(payload.last).to eq({
        "alg" => "HS256",
      })
    end
  end
end
