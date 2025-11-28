require "rails_helper"

RSpec.describe OneLogin::JwksCache do
  before do
    described_class.clear_cache!
  end

  describe "::document" do
    context "when there is nothing cached" do
      before do
        stub_normal_jwks
      end

      it "fetches jwks, caches it, returns it" do
        expect(described_class.cache.document_object).to be_nil
        expect(described_class.document.algorithms).to eql(["ES256", "RS256"])
      end

      it "only makes one http request" do
        3.times do
          described_class.document
        end

        expect(stub_normal_jwks).to have_been_made.once
      end
    end

    context "when document is cached" do
      context "when expired" do
        before do
          stub_normal_jwks
          described_class.document
        end

        it "fetches new document" do
          travel 25.hours do
            described_class.document
            expect(stub_normal_jwks).to have_been_made.twice
          end
        end
      end

      context "when expired and not 200" do
        before do
          stub_failure_jwks
          described_class.document
        end

        it "keeps cached version" do
          travel 25.hours do
            expect(described_class.document.algorithms).to eql(["ES256", "RS256"])
          end
        end

        it "increments expiry" do
          travel 25.hours do
            expect { described_class.cache.document }.to change { described_class.cache.expires_at }.by(1.hour)
          end
        end
      end
    end
  end

  def stub_normal_jwks
    return_headers = {
      "Cache-Control" => "max-age=86400"
    }

    return_body = '{
  "keys": [
    {
      "kty": "EC",
      "use": "sig",
      "crv": "P-256",
      "kid": "644af598b780f54106ca0f3c017341bc230c4f8373f35f32e18e3e40cc7acff6",
      "x": "5URVCgH4HQgkg37kiipfOGjyVft0R5CdjFJahRoJjEw",
      "y": "QzrvsnDy3oY1yuz55voaAq9B1M5tfhgW3FBjh_n_F0U",
      "alg": "ES256"
    },
    {
      "kty": "EC",
      "use": "sig",
      "crv": "P-256",
      "kid": "e1f5699d068448882e7866b49d24431b2f21bf1a8f3c2b2dde8f4066f0506f1b",
      "x": "BJnIZvnzJ9D_YRu5YL8a3CXjBaa5AxlX1xSeWDLAn9k",
      "y": "x4FU3lRtkeDukSWVJmDuw2nHVFVIZ8_69n4bJ6ik4bQ",
      "alg": "ES256"
    },
    {
      "kty": "RSA",
      "e": "AQAB",
      "use": "sig",
      "kid": "76e79bfc350137593e5bd992b202e248fc97e7a20988a5d4fbe9a0273e54844e",
      "alg": "RS256",
      "n": "lGac-hw2cW5_amtNiDI-Nq2dEXt1x0nwOEIEFd8NwtYz7ha1GzNwO2LyFEoOvqIAcG0NFCAxgjkKD5QwcsThGijvMOLG3dPRMjhyB2S4bCmlkwLpW8vY4sJjc4bItdfuBtUxDA0SWqepr5h95RAsg9UP1LToJecJJR_duMzN-Nutu9qwbpIJph8tFjOFp_T37bVFk4vYkWfX-d4-TOImOOD75G0kgYoAJLS2SRovQAkbJwC1bdn_N8yw7RL9WIqZCwzqMqANdo3dEgSb04XD_CUzL0Y2zU3onewH9PhaMfb11JhsuijH3zRA0dwignDHp7pBw8uMxYSqhoeVO6V0jz8vYo27LyySR1ZLMg13bPNrtMnEC-LlRtZpxkcDLm7bkO-mPjYLrhGpDy7fSdr-6b2rsHzE_YerkZA_RgX_Qv-dZueX5tq2VRZu66QJAgdprZrUx34QBitSAvHL4zcI_Qn2aNl93DR-bT8lrkwB6UBz7EghmQivrwK84BjPircDWdivT4GcEzRdP0ed6PmpAmerHaalyWpLUNoIgVXLa_Px07SweNzyb13QFbiEaJ8p1UFT05KzIRxO8p18g7gWpH8-6jfkZtTOtJJKseNRSyKHgUK5eO9kgvy9sRXmmflV6pl4AMOEwMf4gZpbKtnLh4NETdGg5oSXEuTiF2MjmXE"
    }
  ]
}'

    stub_request(:get, "https://oidc.integration.account.gov.uk/.well-known/jwks.json")
      .with(
        headers: {
          "Accept" => "*/*",
          "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "Host" => "oidc.integration.account.gov.uk",
          "User-Agent" => "Ruby"
        }
      )
      .to_return(status: 200, body: return_body, headers: return_headers)
  end

  def stub_failure_jwks
    return_headers = {
      "Cache-Control" => "max-age=86400"
    }

    return_body = '{
  "keys": [
    {
      "kty": "EC",
      "use": "sig",
      "crv": "P-256",
      "kid": "644af598b780f54106ca0f3c017341bc230c4f8373f35f32e18e3e40cc7acff6",
      "x": "5URVCgH4HQgkg37kiipfOGjyVft0R5CdjFJahRoJjEw",
      "y": "QzrvsnDy3oY1yuz55voaAq9B1M5tfhgW3FBjh_n_F0U",
      "alg": "ES256"
    },
    {
      "kty": "EC",
      "use": "sig",
      "crv": "P-256",
      "kid": "e1f5699d068448882e7866b49d24431b2f21bf1a8f3c2b2dde8f4066f0506f1b",
      "x": "BJnIZvnzJ9D_YRu5YL8a3CXjBaa5AxlX1xSeWDLAn9k",
      "y": "x4FU3lRtkeDukSWVJmDuw2nHVFVIZ8_69n4bJ6ik4bQ",
      "alg": "ES256"
    },
    {
      "kty": "RSA",
      "e": "AQAB",
      "use": "sig",
      "kid": "76e79bfc350137593e5bd992b202e248fc97e7a20988a5d4fbe9a0273e54844e",
      "alg": "RS256",
      "n": "lGac-hw2cW5_amtNiDI-Nq2dEXt1x0nwOEIEFd8NwtYz7ha1GzNwO2LyFEoOvqIAcG0NFCAxgjkKD5QwcsThGijvMOLG3dPRMjhyB2S4bCmlkwLpW8vY4sJjc4bItdfuBtUxDA0SWqepr5h95RAsg9UP1LToJecJJR_duMzN-Nutu9qwbpIJph8tFjOFp_T37bVFk4vYkWfX-d4-TOImOOD75G0kgYoAJLS2SRovQAkbJwC1bdn_N8yw7RL9WIqZCwzqMqANdo3dEgSb04XD_CUzL0Y2zU3onewH9PhaMfb11JhsuijH3zRA0dwignDHp7pBw8uMxYSqhoeVO6V0jz8vYo27LyySR1ZLMg13bPNrtMnEC-LlRtZpxkcDLm7bkO-mPjYLrhGpDy7fSdr-6b2rsHzE_YerkZA_RgX_Qv-dZueX5tq2VRZu66QJAgdprZrUx34QBitSAvHL4zcI_Qn2aNl93DR-bT8lrkwB6UBz7EghmQivrwK84BjPircDWdivT4GcEzRdP0ed6PmpAmerHaalyWpLUNoIgVXLa_Px07SweNzyb13QFbiEaJ8p1UFT05KzIRxO8p18g7gWpH8-6jfkZtTOtJJKseNRSyKHgUK5eO9kgvy9sRXmmflV6pl4AMOEwMf4gZpbKtnLh4NETdGg5oSXEuTiF2MjmXE"
    }
  ]
}'

    stub_request(:get, "https://oidc.integration.account.gov.uk/.well-known/jwks.json")
      .with(
        headers: {
          "Accept" => "*/*",
          "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "Host" => "oidc.integration.account.gov.uk",
          "User-Agent" => "Ruby"
        }
      )
      .to_return(status: 200, body: return_body, headers: return_headers)
      .to_return(status: 500, body: "{}", headers: return_headers)
  end
end
