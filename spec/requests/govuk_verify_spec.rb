require "rails_helper"

RSpec.describe "GOV.UK Verify requests", type: :request do
  describe "verify/authentications/new" do
    before do
      get new_verify_authentication_path
    end

    it "renders a form that will submit an authentication request to Verify" do
      get new_verify_authentication_path

      expect(response.body).to include("action=\"SSO_LOCATION\"")
      expect(response.body).to include("SAML_REQUEST")
    end
  end
end
