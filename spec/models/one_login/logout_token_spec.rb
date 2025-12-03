require "rails_helper"

RSpec.describe OneLogin::LogoutToken do
  subject { described_class.new(jwt: token.to_s) }

  let(:iat) { 3.hours.ago }
  let(:exp) { 2.hours.from_now }

  let(:jwk_hash) do
    {
      kty: "EC",
      d: "HezLkoNIljRB4Vr00UYXnj4uLc1mvAnyJGUdOJMpymM",
      crv: "P-256",
      kid: "QmVx6Z4hnj3YcBL-psgDabBzj1SooPTGaJZ7_F5bymo",
      x: "lIETndhvhFXuDTZxayyLDxx793hiEM0NFCIpC33SWnM",
      y: "kACuMsxQHsGPcGmsLSaYLTpPZNqv_4onf6LDIjlv-fQ",
      alg: "ES256"
    }
  end

  let(:jwk) { JWT::JWK.import(jwk_hash) }
  let(:token) { JWT::Token.new(payload:, header:) }
  let(:onelogin_uid) { SecureRandom.uuid }

  let(:header) { {kid: "QmVx6Z4hnj3YcBL-psgDabBzj1SooPTGaJZ7_F5bymo"} }

  let(:body_hash) do
    {
      keys: [
        {
          kty: "EC",
          use: "sig",
          crv: "P-256",
          kid: "644af598b780f54106ca0f3c017341bc230c4f8373f35f32e18e3e40cc7acff6",
          x: "5URVCgH4HQgkg37kiipfOGjyVft0R5CdjFJahRoJjEw",
          y: "QzrvsnDy3oY1yuz55voaAq9B1M5tfhgW3FBjh_n_F0U",
          alg: "ES256"
        },
        {
          kty: "EC",
          use: "sig",
          crv: "P-256",
          kid: "QmVx6Z4hnj3YcBL-psgDabBzj1SooPTGaJZ7_F5bymo",
          x: "lIETndhvhFXuDTZxayyLDxx793hiEM0NFCIpC33SWnM",
          y: "kACuMsxQHsGPcGmsLSaYLTpPZNqv_4onf6LDIjlv-fQ",
          alg: "ES256"
        },
        {
          kty: "RSA",
          e: "AQAB",
          use: "sig",
          kid: "76e79bfc350137593e5bd992b202e248fc97e7a20988a5d4fbe9a0273e54844e",
          alg: "RS256",
          n: "lGac-hw2cW5_amtNiDI-Nq2dEXt1x0nwOEIEFd8NwtYz7ha1GzNwO2LyFEoOvqIAcG0NFCAxgjkKD5QwcsThGijvMOLG3dPRMjhyB2S4bCmlkwLpW8vY4sJjc4bItdfuBtUxDA0SWqepr5h95RAsg9UP1LToJecJJR_duMzN-Nutu9qwbpIJph8tFjOFp_T37bVFk4vYkWfX-d4-TOImOOD75G0kgYoAJLS2SRovQAkbJwC1bdn_N8yw7RL9WIqZCwzqMqANdo3dEgSb04XD_CUzL0Y2zU3onewH9PhaMfb11JhsuijH3zRA0dwignDHp7pBw8uMxYSqhoeVO6V0jz8vYo27LyySR1ZLMg13bPNrtMnEC-LlRtZpxkcDLm7bkO-mPjYLrhGpDy7fSdr-6b2rsHzE_YerkZA_RgX_Qv-dZueX5tq2VRZu66QJAgdprZrUx34QBitSAvHL4zcI_Qn2aNl93DR-bT8lrkwB6UBz7EghmQivrwK84BjPircDWdivT4GcEzRdP0ed6PmpAmerHaalyWpLUNoIgVXLa_Px07SweNzyb13QFbiEaJ8p1UFT05KzIRxO8p18g7gWpH8-6jfkZtTOtJJKseNRSyKHgUK5eO9kgvy9sRXmmflV6pl4AMOEwMf4gZpbKtnLh4NETdGg5oSXEuTiF2MjmXE"
        }
      ]
    }
  end

  let(:payload) do
    {
      iss: "https://oidc.integration.account.gov.uk/",
      sub: onelogin_uid,
      aud: ENV["ONELOGIN_SIGN_IN_CLIENT_ID"],
      iat: iat.to_i,
      exp: exp.to_i,
      jti: "30642c87-6167-413f-8ace-f1643c59e398",
      events: {
        "http://schemas.openid.net/event/backchannel-logout": {}
      }
    }
  end

  before do
    stub_request(:get, "https://oidc.integration.account.gov.uk/.well-known/jwks.json")
      .with(
       headers: {
         "Accept" => "*/*",
         "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
         "Host" => "oidc.integration.account.gov.uk",
         "User-Agent" => "Ruby"
       }
     )
      .to_return(status: 200, body: body_hash.to_json, headers: {})

    token.sign!(key: jwk, algorithm: "ES256")
  end

  after :each do
    OneLogin::JwksCache.clear_cache!
  end

  describe "#valid?" do
    context "when iss claim is invalid" do
      let(:payload) do
        {
          iss: "WRONG_ISS",
          sub: onelogin_uid,
          aud: "YOUR_CLIENT_ID",
          iat: iat.to_i,
          exp: exp.to_i,
          jti: "30642c87-6167-413f-8ace-f1643c59e398",
          events: {
            "http://schemas.openid.net/event/backchannel-logout": {}
          }
        }
      end

      it "returns false" do
        expect(subject.valid?).to be_falsey
      end
    end

    context "when aud claim is invalid" do
      let(:payload) do
        {
          iss: "https://oidc.integration.account.gov.uk/",
          sub: onelogin_uid,
          aud: "WRONG_CLIENT_ID",
          iat: iat.to_i,
          exp: exp.to_i,
          jti: "30642c87-6167-413f-8ace-f1643c59e398",
          events: {
            "http://schemas.openid.net/event/backchannel-logout": {}
          }
        }
      end

      it "returns false" do
        expect(subject.valid?).to be_falsey
      end
    end

    context "when signature is invalid" do
      let(:jwk_hash) do
        {
          kty: "EC",
          d: "5648P5r8faUZlEnqRkKbdyyVvuBaCxxaI5jJC9Jp1Ks",
          crv: "P-256",
          kid: "QmVx6Z4hnj3YcBL-psgDabBzj1SooPTGaJZ7_F5bymo",
          x: "RUyBtv1KgafKNJsjWVdALvqdXWPU2p_lTU5gHaGjqNk",
          y: "DBO82jffDgGUqRqAv9iwHVH42C8pPppUuPPfTtdzWvs",
          alg: "ES256"
        }
      end

      it "returns false" do
        expect(subject.valid?).to be_falsey
      end
    end

    context "when expired is invalid" do
      let(:exp) { 2.hours.ago }

      it "returns false" do
        expect(subject.valid?).to be_falsey
      end
    end

    context "when iat is invalid" do
      let(:iat) { 2.hours.from_now }

      it "returns false" do
        expect(subject.valid?).to be_falsey
      end
    end
  end

  describe "#user_uid" do
    it "returns OL uid" do
      expect(subject.user_uid).to eql(onelogin_uid)
    end
  end
end
