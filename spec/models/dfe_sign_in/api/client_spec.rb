require "rails_helper"

RSpec.describe DfeSignIn::Api::Client, type: :model do
  # legacy test for private method
  describe "#generate_jwt_token" do
    around do |example|
      freeze_time { example.run }
    end

    subject do
      described_class.new(client_id: "teacherpayments")
    end

    let(:jwt_token) { subject.send(:generate_jwt_token) }

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
