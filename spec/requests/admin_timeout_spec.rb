require "rails_helper"

RSpec.describe "Admin session timing out", type: :request do
  let(:timeout_length_in_minutes) { Admin::BaseAdminController::TIMEOUT_LENGTH_IN_MINUTES }

  before do
    OmniAuth.config.mock_auth[:dfe] = OmniAuth::AuthHash.new(
      "provider" => "dfe",
      "info" => {"email" => "test-dfe-sign-in@host.tld"},
      "extra" => {
        "raw_info" => {
          "organisation" => {
            "id" => "3bb6e3d7-64a9-42d8-b3f7-cf26101f3e82",
          },
        },
      }
    )
    stub_authorised_user!
    post admin_dfe_sign_in_path
    follow_redirect!
  end

  context "no actions performed for more than the timeout period" do
    let(:after_expiry) { timeout_length_in_minutes.minutes + 1.second }

    it "clears the session and redirects to the login page" do
      expect(session[:login]).to eql({"email" => "test-dfe-sign-in@host.tld"})
      expect(session[:last_seen_at]).not_to be_nil

      travel after_expiry do
        get admin_claims_path(format: :csv)

        expect(response).to redirect_to(admin_sign_in_path)
        expect(session[:login]).to be_nil
        expect(session[:last_seen_at]).to be_nil
        follow_redirect!
        expect(response.body).to include("Your session has timed out due to inactivity")
      end
    end
  end

  context "no action performed just within the timeout period" do
    let(:before_expiry) { timeout_length_in_minutes.minutes - 2.seconds }

    it "does not timeout the session" do
      travel before_expiry do
        get admin_claims_path(format: :csv)

        expect(response.code).to eq("200")
        expect(session[:login]).to_not be_nil
        expect(session[:last_seen_at]).to_not be_nil
      end
    end
  end
end
