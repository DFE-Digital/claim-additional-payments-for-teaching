require "rails_helper"

RSpec.describe OneLogin::LogoutToken do
  describe "#valid?" do
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
        "@context": [
          "https://www.w3.org/ns/did/v1",
          "https://w3id.org/security/jwk/v1"
        ],
        id: "did:web:identity.integration.account.gov.uk",
        assertionMethod: [
          {
            type: "JsonWebKey",
            id: "QmVx6Z4hnj3YcBL-psgDabBzj1SooPTGaJZ7_F5bymo",
            controller: "did:web:identity.integration.account.gov.uk",
            publicKeyJwk: {
              kty: "EC",
              crv: "P-256",
              x: "lIETndhvhFXuDTZxayyLDxx793hiEM0NFCIpC33SWnM",
              y: "kACuMsxQHsGPcGmsLSaYLTpPZNqv_4onf6LDIjlv-fQ",
              alg: "ES256"
            }
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
      stub_request(:get, "https://identity.integration.account.gov.uk/.well-known/did.json")
        .with(
         headers: {
           "Accept" => "*/*",
           "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
           "Host" => "identity.integration.account.gov.uk",
           "User-Agent" => "Ruby"
         }
       )
        .to_return(status: 200, body: body_hash.to_json, headers: {})

      token.sign!(key: jwk, algorithm: "ES256")
    end

    subject { described_class.new(jwt: token.to_s) }

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
end
