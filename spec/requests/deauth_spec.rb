require "rails_helper"

RSpec.describe "logging out", type: :request do
  before do
    create(:journey_configuration, :further_education_payments)
  end

  context "of one login" do
    it "clears session variables" do
      get "/further-education-payments/claim"

      session[:foo] = "bar"

      delete "/deauth/onelogin"

      expect(session[:foo]).to be_nil
    end

    it "changes to new session" do
      get "/further-education-payments/claim"

      expect {
        delete "/deauth/onelogin"
      }.to change { session[:session_id] }
    end

    it "redirects to one login" do
      stub_const "ENV", ENV.to_h.merge("BYPASS_ONELOGIN_SIGN_IN" => nil)

      get "/further-education-payments/claim"

      journey_session = Journeys::FurtherEducationPayments::Session.last
      journey_session.answers.onelogin_credentials = {"id_token" => "some_token"}
      journey_session.save!

      delete "/deauth/onelogin"

      expect(response).to redirect_to("https://oidc.integration.account.gov.uk/logout?id_token_hint=some_token&post_logout_redirect_uri=http://www.example.com/deauth/onelogin/callback&state=further-education-payments")
    end

    context "when OL bypassed" do
      it "redirects to journey start page" do
        stub_const "ENV", ENV.to_h.merge("BYPASS_ONELOGIN_SIGN_IN" => "true")

        get "/further-education-payments/claim"
        delete "/deauth/onelogin"

        expect(response).to redirect_to("http://www.example.com/further-education-payments/landing-page")
      end
    end
  end

  context "with onelogin callback" do
    it "redirects to relevant start page" do
      get "/deauth/onelogin/callback?state=further-education-payments"

      expect(response).to redirect_to("/further-education-payments/landing-page")
    end
  end

  context "onelogin back channel" do
    context "when no such session is found" do
      let(:onelogin_uid) { SecureRandom.uuid }
      let(:jwt_logout_token) { "FAKE_TOKEN" }

      let(:token_double) do
        OneLogin::LogoutToken.new(jwt: "FAKE_TOKEN")
      end

      before do
        allow(OneLogin::LogoutToken).to receive(:new).and_return(token_double)

        allow(token_double).to receive(:valid?).and_return(true)
        allow(token_double).to receive(:user_uid).and_return(onelogin_uid)
      end

      it "returns 200" do
        post "/deauth/onelogin/back-channel",
          headers: {
            "Content-Type" => "application/x-www-form-urlencoded"
          },
          params: {
            "logout_token" => jwt_logout_token
          }

        expect(response).to be_ok
      end
    end

    context "when session exists" do
      let(:jwt_logout_token) { "FAKE_TOKEN" }
      let(:onelogin_uid) { answers.onelogin_uid }

      let!(:journey_session) do
        create(
          :further_education_payments_session,
          answers:
        )
      end

      let(:answers) do
        build(
          :further_education_payments_answers,
          :signed_in_with_one_login
        )
      end

      let(:token_double) do
        OneLogin::LogoutToken.new(jwt: "FAKE_TOKEN")
      end

      before do
        allow(OneLogin::LogoutToken).to receive(:new).and_return(token_double)

        allow(token_double).to receive(:valid?).and_return(true)
        allow(token_double).to receive(:user_uid).and_return(onelogin_uid)
      end

      it "return 200 and revokes existing session" do
        expect {
          post "/deauth/onelogin/back-channel",
            headers: {
              "Content-Type" => "application/x-www-form-urlencoded"
            },
            params: {
              "logout_token" => jwt_logout_token
            }
        }.to change { journey_session.reload.expired? }.from(false).to(true)

        expect(response).to be_ok
      end
    end

    context "when logout token has invalid iat" do
      let(:jwk_hash) do
        {
          kty: "EC",
          d: "ujsXByc2TFEpiUihtQW-XTTvib5gSVEguSNZ03zjRPo",
          crv: "P-256",
          kid: "kDfCkfr98AodHydaj2L9cFtncwBcr4DLVzwA8-yzOeg",
          x: "NNR2vWlDx3iwJopx3HoETkGTefmEIxuDSC5w35fbsAs",
          y: "qcnqxul4WVuYpuplZA7iNhKO3qBF9S9NTWqEg6N7Lrs",
          alg: "ES256"
        }
      end

      let(:jwk) { JWT::JWK.import(jwk_hash) }
      let(:token) { JWT::Token.new(payload:, header:) }

      let(:header) { {kid: "kDfCkfr98AodHydaj2L9cFtncwBcr4DLVzwA8-yzOeg"} }
      let(:payload) do
        {
          iss: "https://oidc.integration.account.gov.uk/",
          sub: journey_session.answers.onelogin_uid,
          aud: "YOUR_CLIENT_ID",
          iat: iat.to_i,
          exp: exp.to_i,
          jti: "30642c87-6167-413f-8ace-f1643c59e398",
          events: {
            "http://schemas.openid.net/event/backchannel-logout": {}
          }
        }
      end

      let!(:journey_session) do
        create(
          :further_education_payments_session,
          answers:
        )
      end

      let(:answers) do
        build(
          :further_education_payments_answers,
          :signed_in_with_one_login
        )
      end

      let(:iat) { 3.hours.from_now }
      let(:exp) { 2.hours.from_now }

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
              id: "kDfCkfr98AodHydaj2L9cFtncwBcr4DLVzwA8-yzOeg",
              controller: "did:web:identity.integration.account.gov.uk",
              publicKeyJwk: {
                kty: "EC",
                crv: "P-256",
                x: "NNR2vWlDx3iwJopx3HoETkGTefmEIxuDSC5w35fbsAs",
                y: "qcnqxul4WVuYpuplZA7iNhKO3qBF9S9NTWqEg6N7Lrs",
                alg: "ES256"
              }
            }
          ]
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
      end

      it "returns 400" do
        token.sign!(key: jwk, algorithm: "ES256")

        post "/deauth/onelogin/back-channel",
          headers: {
            "Content-Type" => "application/x-www-form-urlencoded"
          },
          params: {
            "logout_token" => token
          }

        expect(response).to be_bad_request
      end
    end
  end
end
