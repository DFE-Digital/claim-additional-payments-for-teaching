require "rails_helper"

RSpec.describe OneLogin::CoreIdentityValidator do
  before do
    OneLogin::DidCache.clear_cache!
  end

  let(:jwt) do
    "eyJraWQiOiJkaWQ6d2ViOmlkZW50aXR5LmludGVncmF0aW9uLmFjY291bnQuZ292LnVrI2M5ZjhkYTFjODc1MjViYjQxNjUzNTgzYzJkMDUyNzRlODU4MDVhYjdkMGFiYzU4Mzc2YzcxMjgxMjlkYWE5MzYiLCJhbGciOiJFUzI1NiJ9.eyJzdWIiOiJ1cm46ZmRjOmdvdi51azoyMDIyOmVOaEd2dWFtZXZYUXVGcVVSdDdPTjZsZHZMQU5SSExqZS1hU2lUWWtRUVUiLCJhdWQiOiJQU1RSRG1QRXFtTkhWalZHV0d3OTk0bk4xY0EiLCJuYmYiOjE3MjM1NDg3NTEsImlzcyI6Imh0dHBzOi8vaWRlbnRpdHkuaW50ZWdyYXRpb24uYWNjb3VudC5nb3YudWsvIiwidm90IjoiUDIiLCJleHAiOjE3MjM1NTA1NTEsImlhdCI6MTcyMzU0ODc1MSwidmMiOnsidHlwZSI6WyJWZXJpZmlhYmxlQ3JlZGVudGlhbCIsIklkZW50aXR5Q2hlY2tDcmVkZW50aWFsIl0sImNyZWRlbnRpYWxTdWJqZWN0Ijp7Im5hbWUiOlt7Im5hbWVQYXJ0cyI6W3sidmFsdWUiOiJLRU5ORVRIIiwidHlwZSI6IkdpdmVuTmFtZSJ9LHsidmFsdWUiOiJERUNFUlFVRUlSQSIsInR5cGUiOiJGYW1pbHlOYW1lIn1dfV0sImJpcnRoRGF0ZSI6W3sidmFsdWUiOiIxOTY1LTA3LTA4In1dfX0sInZ0bSI6Imh0dHBzOi8vb2lkYy5pbnRlZ3JhdGlvbi5hY2NvdW50Lmdvdi51ay90cnVzdG1hcmsifQ.mKZ4BK01BZn1I6ziPB4zdF0o0yIKUC6hU4k8R-qp6khcTXKMgxrPbWRD7CzLae-bst9cp3bFGtbpHzDpX72W3Q"
  end

  subject { described_class.new(jwt:) }

  describe "#call" do
    context "when valid" do
      before do
        stub_normal_did
      end

      it "decodes payload corectly" do
        travel_to(Time.at(1723548751)) do
          expect(subject.call[0]["vc"]["credentialSubject"]["name"][0]["nameParts"][0]["value"]).to eql("KENNETH")
        end
      end
    end

    context "when bad public key" do
      before do
        stub_bad_did
      end

      it do
        travel_to(Time.at(1723548751)) do
          expect { subject.call }.to raise_error(JWT::VerificationError)
        end
      end
    end
  end

  describe "#first_name" do
    before do
      stub_normal_did

      travel_to(Time.at(1723548751)) do
        subject.call
      end
    end

    it "returns first name" do
      expect(subject.first_name).to eql("KENNETH")
    end
  end

  describe "#last_name" do
    before do
      stub_normal_did

      travel_to(Time.at(1723548751)) do
        subject.call
      end
    end

    it "returns last name" do
      expect(subject.last_name).to eql("DECERQUEIRA")
    end
  end

  describe "#date_of_birth" do
    before do
      stub_normal_did

      travel_to(Time.at(1723548751)) do
        subject.call
      end
    end

    it "returns date of birth" do
      expect(subject.date_of_birth).to eql(Date.new(1965, 7, 8))
    end
  end

  describe "#full_name" do
    before do
      stub_normal_did

      travel_to(Time.at(1723548751)) do
        subject.call
      end
    end

    it "returns whole name" do
      expect(subject.full_name).to eql("KENNETH DECERQUEIRA")
    end

    context "if name parts is out of order" do
      it "ensures family name is used as last name" do
        out_of_order = [
          {"value" => "DECERQUEIRA", "type" => "FamilyName"},
          {"value" => "KENNETH", "type" => "GivenName"}
        ]

        allow(subject).to receive(:name_parts).and_return(out_of_order)

        expect(subject.full_name).to eql("KENNETH DECERQUEIRA")
      end
    end
  end

  let(:stub_normal_did) do
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

  let(:stub_bad_did) do
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
      "x": "Vm7_Vhz07e9UoblDw1rmd29bV6ykcut4npLnqhhQlVk",
      "y": "uISs1AK-TVo0duSg3AvFuBNgBPp7ex4dWmYvkFN8uRk",
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
end
