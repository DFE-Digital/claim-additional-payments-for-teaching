require "rails_helper"

RSpec.describe OneLogin::Did do
  let(:body) do
    '{
  "@context" : [ "https://www.w3.org/ns/did/v1", "https://w3id.org/security/jwk/v1" ],
  "id" : "did:web:identity.integration.account.gov.uk",
  "assertionMethod" : [ {
    "type" : "JsonWebKey",
    "id" : "did:web:identity.integration.account.gov.uk#c9f8da1c87525bb41653583c2d05274e85805ab7d0abc58376c7128129daa936",
    "controller" : "did:web:identity.integration.account.gov.uk",
    "publicKeyJwk" : {
      "kty" : "EC",
      "crv" : "P-256",
      "x" : "NPGA7cyIKtH1nz2CJIH14s9_CtC93NwdCQcEi-ADvxg",
      "y" : "2cTdmHAmZjighly34lXcxEw50cbKFV7FTOdZKhOG7ps",
      "alg" : "ES256"
    }
  } ]
}'
  end

  subject { described_class.new(document_hash: JSON.parse(body)) }

  describe "#context" do
    it "returns context" do
      expect(subject.context).to eql(["https://www.w3.org/ns/did/v1", "https://w3id.org/security/jwk/v1"])
    end
  end

  describe "#id" do
    it "returns id" do
      expect(subject.id).to eql("did:web:identity.integration.account.gov.uk")
    end
  end

  describe "#assertion_methods" do
    it "is an collection" do
      expect(subject.assertion_methods).to be_an(Array)
    end
  end
end
