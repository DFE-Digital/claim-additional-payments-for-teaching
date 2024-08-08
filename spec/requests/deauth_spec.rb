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
      get "/further-education-payments/claim"

      journey_session = Journeys::FurtherEducationPayments::Session.last
      journey_session.answers.onelogin_credentials = {id_token: "some_token"}
      journey_session.save!

      delete "/deauth/onelogin"

      expect(response).to redirect_to("https://oidc.integration.account.gov.uk/logout?id_token_hint=some_token&post_logout_redirect_uri=http://www.example.com/deauth/onelogin/callback&state=further-education-payments")
    end
  end

  context "with onelogin callback" do
    it "redirects to relevant start page" do
      get "/deauth/onelogin/callback?state=further-education-payments"

      expect(response).to redirect_to("/further-education-payments/landing-page")
    end
  end
end
