require "rails_helper"

RSpec.describe "Admin session timing out", type: :request do
  let(:timeout_length_in_minutes) { ApplicationController::ADMIN_TIMEOUT_LENGTH_IN_MINUTES }

  before do
    stub_dfe_sign_in_with_role(Admin::AuthController::DFE_SIGN_IN_ADMIN_ROLE_CODE)
    post admin_dfe_sign_in_path
    follow_redirect!
  end

  context "no actions performed for more than the timeout period" do
    let(:after_expiry) { timeout_length_in_minutes.minutes + 1.second }

    it "clears the session and redirects to the login page" do
      expect(session[:admin_auth]).to eql({"email" => "test-dfe-sign-in@host.tld"})

      travel after_expiry do
        get admin_claims_path(format: :csv)

        expect(response).to redirect_to(admin_sign_in_path)
        expect(session[:admin_auth]).to be_nil

        follow_redirect!
        expect(response.body).to include("Your session has timed out due to inactivity")
      end
    end
  end

  context "user visits a non-admin page after the timeout period" do
    let(:after_expiry) { timeout_length_in_minutes.minutes + 1.second }

    it "still clears the admin session" do
      expect(session[:admin_auth]).to eql({"email" => "test-dfe-sign-in@host.tld"})

      travel after_expiry do
        get root_path

        expect(session[:admin_auth]).to be_nil
        expect(response).to be_successful
      end
    end
  end

  context "no action performed just within the timeout period" do
    let(:before_expiry) { timeout_length_in_minutes.minutes - 2.seconds }

    it "does not timeout the session" do
      travel before_expiry do
        get admin_claims_path(format: :csv)

        expect(response.code).to eq("200")
        expect(session[:admin_auth]).to_not be_nil
      end
    end
  end
end
