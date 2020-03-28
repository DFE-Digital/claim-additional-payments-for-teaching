require "rails_helper"

RSpec.describe "Admin session timing out", type: :request do
  let(:timeout_length_in_minutes) { AdminSessionTimeout::ADMIN_TIMEOUT_LENGTH_IN_MINUTES }
  let(:dfe_sign_in_id) { "userid-345" }

  let!(:user) { create(:dfe_signin_user, dfe_sign_in_id: dfe_sign_in_id) }

  let(:before_expiry) { timeout_length_in_minutes.minutes - 2.seconds }
  let(:after_expiry) { timeout_length_in_minutes.minutes + 1.second }

  before do
    sign_in_to_admin_with_role(DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE, dfe_sign_in_id)
  end

  it "clears the session and redirects to the login page when no actions have been performed during the timeout period" do
    expect(session[:user_id]).to eq(user.id)

    travel after_expiry do
      get admin_claims_path

      expect(response).to redirect_to(admin_sign_in_path)
      expect(session[:user_id]).to be_nil

      follow_redirect!
      expect(response.body).to include("Your session has timed out due to inactivity")
    end
  end

  it "does not extend the session when the user performs a claim action" do
    travel after_expiry do
      start_student_loans_claim
      get admin_claims_path

      expect(response).to redirect_to(admin_sign_in_path)
      expect(session[:user_id]).to be_nil

      follow_redirect!
      expect(response.body).to include("Your session has timed out due to inactivity")
    end
  end

  it "does not timeout the session when an action is performed within the timeout period" do
    travel before_expiry do
      get admin_claims_path

      expect(response.code).to eq("200")
      expect(session[:user_id]).to_not be_nil
    end
  end
end
