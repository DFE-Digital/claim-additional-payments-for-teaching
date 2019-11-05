require "rails_helper"

RSpec.describe "Admin session timing out", type: :request do
  let(:timeout_length_in_minutes) { Admin::BaseAdminController::ADMIN_TIMEOUT_LENGTH_IN_MINUTES }
  let(:user_id) { "userid-345" }
  let(:organisation_id) { "organisationid-6789" }

  before do
    sign_in_to_admin_with_role(AdminSession::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE, user_id, organisation_id)
  end

  context "no actions performed for more than the timeout period" do
    let(:after_expiry) { timeout_length_in_minutes.minutes + 1.second }

    it "clears the session and redirects to the login page" do
      expect(session[:user_id]).to eq(user_id)
      expect(session[:organisation_id]).to eq(organisation_id)
      expect(session[:role_codes]).to eq([AdminSession::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE])

      travel after_expiry do
        get admin_claims_path

        expect(response).to redirect_to(admin_sign_in_path)
        expect(session[:user_id]).to be_nil
        expect(session[:organisation_id]).to be_nil
        expect(session[:role_codes]).to be_nil

        follow_redirect!
        expect(response.body).to include("Your session has timed out due to inactivity")
      end
    end
  end

  context "no action performed just within the timeout period" do
    let(:before_expiry) { timeout_length_in_minutes.minutes - 2.seconds }

    it "does not timeout the session" do
      travel before_expiry do
        get admin_claims_path

        expect(response.code).to eq("200")
        expect(session[:user_id]).to_not be_nil
        expect(session[:organisation_id]).to_not be_nil
        expect(session[:role_codes]).to_not be_nil
      end
    end
  end
end
