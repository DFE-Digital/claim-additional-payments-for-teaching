require "rails_helper"
require "verify/fake_sso"

RSpec.describe Verify::FakeSso do
  include Rack::Test::Methods

  describe "POST to /verified" do
    let(:callback_url) { "/verify/response" }
    let(:app) { Verify::FakeSso.new(callback_url) }
    let(:success_response) { Verify::FakeSso::IDENTITY_VERIFIED_SAML_RESPONSE }

    it "returns a HTML form that will POST back to the app with a successful SAML response parameter" do
      post "/verified"

      expect(last_response.status).to eq(200)
      expect(last_response.content_type).to eq "text/html"
      expect(last_response.body).to include "<form action=\"#{callback_url}\" method=\"POST\">"
      expect(last_response.body).to include "<input type=\"hidden\" name=\"SAMLResponse\" value=\"#{success_response}\">"
    end
  end
end
