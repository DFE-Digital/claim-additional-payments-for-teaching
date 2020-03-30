require "rails_helper"

RSpec.describe "Admin session timing out", type: :request do
  let(:timeout_length_in_minutes) { AdminSessionTimeout::ADMIN_TIMEOUT_LENGTH_IN_MINUTES }

  let(:before_expiry) { timeout_length_in_minutes.minutes - 2.seconds }
  let(:after_expiry) { timeout_length_in_minutes.minutes + 1.second }

  before { @signed_in_user = sign_in_as_service_operator }

  it "clears the session and redirects to the login page when no actions have been performed during the timeout period" do
    expect(session[:user_id]).to eq(@signed_in_user.id)

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
