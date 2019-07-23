require "rails_helper"

RSpec.describe DfeSignIn::Utils do
  before do
    DfeSignIn.configure do |config|
      config.client_id = "123"
      config.secret = "sekrit"
    end
  end

  let(:dummy_class) { Class.new { extend DfeSignIn::Utils } }

  describe "generate_jwt_token" do
    before { freeze_time }
    after { travel_back }

    let(:jwt_token) { dummy_class.generate_jwt_token }

    it "generates a JWT token" do
      expect(jwt_token).to_not eq(nil)
    end

    it "has the correct information" do
      payload = JWT.decode(jwt_token, "sekrit", true, {algorithm: "HS256"})
      expect(payload.first).to eq({
        "iss" => "123",
        "exp" => (Time.now.getlocal + 60).to_i,
        "aud" => "signin.education.gov.uk",
      })
      expect(payload.last).to eq({
        "alg" => "HS256",
      })
    end
  end
end
