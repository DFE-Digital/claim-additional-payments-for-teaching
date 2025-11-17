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
      let(:jwt_logout_token) { "FAKE_TOKEN" }

      let(:iat) { 2.hours.ago }
      let(:exp) { 2.hours.from_now }

      let(:decoded_jwt) do
        [
          { # payload
            iss: "https://oidc.integration.account.gov.uk/",
            sub: "some-uid",
            aud: "YOUR_CLIENT_ID",
            iat: iat.to_i,
            exp: exp.to_i,
            jti: "30642c87-6167-413f-8ace-f1643c59e398",
            events: {
              "http://schemas.openid.net/event/backchannel-logout": {}
            }
          },
          { # headers
            kid: "644af598b780f54106c2465489765230c4f8373f35f32e18e3e40cc7acff6",
            alg: "ES256"
          }
        ]
      end

      let(:token_double) do
        OneLogin::LogoutToken.new(jwt: "FAKE_TOKEN")
      end

      before do
        allow(OneLogin::LogoutToken).to receive(:new).and_return(token_double)

        allow(token_double).to receive(:decoded_jwt).and_return(decoded_jwt)
        allow(token_double).to receive(:user_uid).and_call_original
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

      let(:iat) { 2.hours.ago }
      let(:exp) { 2.hours.from_now }

      let(:decoded_jwt) do
        [
          { # payload
            iss: "https://oidc.integration.account.gov.uk/",
            sub: journey_session.answers.onelogin_uid,
            aud: "YOUR_CLIENT_ID",
            iat: iat.to_i,
            exp: exp.to_i,
            jti: "30642c87-6167-413f-8ace-f1643c59e398",
            events: {
              "http://schemas.openid.net/event/backchannel-logout": {}
            }
          },
          { # headers
            kid: "644af598b780f54106c2465489765230c4f8373f35f32e18e3e40cc7acff6",
            alg: "ES256"
          }
        ]
      end

      let(:token_double) do
        OneLogin::LogoutToken.new(jwt: "FAKE_TOKEN")
      end

      before do
        allow(OneLogin::LogoutToken).to receive(:new).and_return(token_double)

        allow(token_double).to receive(:decoded_jwt).and_return(decoded_jwt)
        allow(token_double).to receive(:user_uid).and_call_original
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
  end
end
