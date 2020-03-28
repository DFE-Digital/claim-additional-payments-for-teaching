require "rails_helper"

RSpec.describe "Admin authentication", type: :request do
  describe "admin requests when not authenticated" do
    it "redirects to the sign in page without setting a session" do
      get admin_root_path

      expect(response).to redirect_to(admin_sign_in_path)
      expect(session[:user_id]).to be_nil
    end
  end

  describe "admin/auth#callback" do
    context "when the user is signing in for the first time" do
      let(:dfe_sign_in_user_id) { SecureRandom.uuid }

      it "creates a DfeSignIn::User record for the user and redirects to the admin root, setting the session ID" do
        expect {
          stub_dfe_sign_in_with_role(DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE, dfe_sign_in_user_id)
          post admin_dfe_sign_in_path
          expect(response).to redirect_to(admin_auth_callback_path)
          follow_redirect!
        }.to change { DfeSignIn::User.count }.by(1)

        new_user = DfeSignIn::User.last

        expect(response).to redirect_to(admin_root_path)
        expect(session[:user_id]).to eq(new_user.id)

        expect(new_user.dfe_sign_in_id).to eq(dfe_sign_in_user_id)
        expect(new_user.role_codes).to eq([DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE])
      end
    end

    context "when the user already has a DfeSignIn::User record" do
      let!(:user) { create(:dfe_signin_user, role_codes: []) }

      it "updates the existing DfeSignIn::User record and redirects to the admin root, setting the session ID" do
        stub_dfe_sign_in_with_role(DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE, user.dfe_sign_in_id)
        post admin_dfe_sign_in_path
        expect(response).to redirect_to(admin_auth_callback_path)
        follow_redirect!

        expect(response).to redirect_to(admin_root_path)
        expect(session[:user_id]).to eq(user.id)
        expect(user.reload.role_codes).to eq([DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE])
      end
    end

    context "when the user requests an authenticated page without having signed in" do
      let(:initial_request_path) { admin_payroll_runs_path }

      before { get initial_request_path }

      it "redirects the user to their originally requested page after they sign in" do
        stub_dfe_sign_in_with_role(DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE)
        post admin_dfe_sign_in_path
        expect(response).to redirect_to(admin_auth_callback_path)
        follow_redirect!

        expect(response).to redirect_to(initial_request_path)
      end
    end

    context "when the user does not have an authorised role" do
      it "returns an Unauthorised response and doesn’t set a session" do
        stub_dfe_sign_in_with_role("not-the-role-code-we-expect")
        post admin_dfe_sign_in_path
        expect(response).to redirect_to(admin_auth_callback_path)
        follow_redirect!

        expect(session[:user_id]).to be_nil

        expect(response.code).to eq("401")
        expect(response.body).to include("Not authorised")
      end
    end

    context "when the callback from DfE Sign-in is for invalid credentials" do
      it "redirects to the auth failure page and doesn’t set a session" do
        OmniAuth.config.mock_auth[:dfe] = :invalid_credentials
        post admin_dfe_sign_in_path
        expect(response).to redirect_to(admin_auth_callback_path)
        follow_redirect!

        expect(session[:user_id]).to be_nil

        expect(response).to redirect_to(
          admin_auth_failure_path(message: :invalid_credentials, strategy: :dfe)
        )
      end
    end
  end

  describe "admin/auth#sign_out" do
    it "clears the session and redirects the user to the sign-in page" do
      delete admin_sign_out_path

      expect(session[:user_id]).to be_nil
      expect(response).to redirect_to(admin_sign_in_path)
    end
  end
end
