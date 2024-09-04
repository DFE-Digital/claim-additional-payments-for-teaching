require "rails_helper"

RSpec.describe "Admin concurrent sessions", type: :request do
  let!(:signed_in_user) { sign_in_as_service_operator }

  it "does not sign out the session when the token matches" do
    old_token = signed_in_user.session_token

    get admin_claims_path

    expect(response).to be_ok
    expect(session[:user_id]).to eq(signed_in_user.id)
    expect(session[:token]).to eq(old_token)
  end

  context "when the user signs in elsewhere" do
    before { signed_in_user.regenerate_session_token }

    it "clears the session and redirects to the login page when no actions have been performed during the timeout period" do
      get admin_claims_path

      expect(response).to redirect_to(admin_sign_in_path)
      expect(session[:user_id]).to be_nil
      expect(session[:token]).to be_nil
    end
  end
end
