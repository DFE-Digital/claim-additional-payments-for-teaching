require "rails_helper"

RSpec.describe OneLogin::Jwks do
  let(:body) do
    '{
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
  end

  subject { described_class.new(document_hash: JSON.parse(body)) }

  describe "#algorithms" do
    it "returns all unique algorithms used by jwks" do
      expect(subject.algorithms).to eql(["ES256", "RS256"])
    end
  end

  describe "#jwks" do
    it "returns set of jwks" do
      expect(subject.jwks.size).to eql(3)
      expect(subject.jwks.keys[0].kid).to eql("644af598b780f54106ca0f3c017341bc230c4f8373f35f32e18e3e40cc7acff6")
      expect(subject.jwks.keys[1].kid).to eql("e1f5699d068448882e7866b49d24431b2f21bf1a8f3c2b2dde8f4066f0506f1b")
      expect(subject.jwks.keys[2].kid).to eql("76e79bfc350137593e5bd992b202e248fc97e7a20988a5d4fbe9a0273e54844e")
    end
  end
end
