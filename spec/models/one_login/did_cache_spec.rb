require "rails_helper"

RSpec.describe OneLogin::DidCache do
  before do
    described_class.clear_cache!
  end

  describe "::document" do
    context "when there is nothing cached" do
      before do
        stub_normal_did
      end

      it "fetches DID, caches it, returns it" do
        expect(OneLogin::DidCache.cache.document_object).to be_nil

        expect(described_class.document.id).to eql("did:web:identity.integration.account.gov.uk")
        expect(described_class.cache.document_object.id).to eql("did:web:identity.integration.account.gov.uk")
      end

      it "only makes one http request" do
        3.times do
          described_class.document
        end

        expect(stub_normal_did).to have_been_made.once
      end
    end

    context "when document is cached" do
      context "when expired" do
        before do
          stub_normal_did
          described_class.document
        end

        it "fetches new document" do
          travel 3.hours do
            described_class.document
            expect(stub_normal_did).to have_been_made.twice
          end
        end
      end

      context "when expired and not 200" do
        before do
          stub_failure_did
          described_class.document
        end

        it "keeps cached version" do
          travel 3.hours do
            expect(described_class.document.id).not_to be_nil
          end
        end

        it "increments expiry" do
          travel 3.hours do
            expect { described_class.cache.document }.to change { described_class.cache.expires_at }.by(1.hour)
          end
        end
      end
    end
  end

  def stub_normal_did
    return_headers = {
      "Cache-Control" => "max-age=3600, private"
    }

    return_body = '{
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

    stub_request(:get, "https://identity.integration.account.gov.uk/.well-known/did.json")
      .with(
        headers: {
          "Accept" => "*/*",
          "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "Host" => "identity.integration.account.gov.uk",
          "User-Agent" => "Ruby"
        }
      )
      .to_return(status: 200, body: return_body, headers: return_headers)
  end

  def stub_failure_did
    return_headers = {
      "Cache-Control" => "max-age=3600, private"
    }

    return_body = '{
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

    stub_request(:get, "https://identity.integration.account.gov.uk/.well-known/did.json")
      .with(
        headers: {
          "Accept" => "*/*",
          "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "Host" => "identity.integration.account.gov.uk",
          "User-Agent" => "Ruby"
        }
      )
      .to_return(status: 200, body: return_body, headers: return_headers)
      .to_return(status: 500, body: "{}", headers: return_headers)
  end
end
