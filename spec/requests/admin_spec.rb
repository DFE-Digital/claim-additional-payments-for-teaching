require "rails_helper"

RSpec.describe "Admin", type: :request do
  describe "admin#index request" do
    context "when the user is not authenticated" do
      it "redirects to the sign in page and doesn’t set a session" do
        get admin_root_path

        expect(response).to redirect_to(admin_sign_in_path)
        expect(session[:user_id]).to be_nil
      end
    end

    context "when the user is authenticated" do
      let(:dfe_sign_in_id) { "userid-345" }
      let(:organisation_id) { "organisationid-6789" }

      let!(:user) { create(:dfe_signin_user, dfe_sign_in_id: dfe_sign_in_id) }

      context "when the user is a service operator" do
        before do
          sign_in_to_admin_with_role(DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE, dfe_sign_in_id, organisation_id)
        end

        it "renders the admin page, sets a session and applies the appropriate role to the user" do
          get admin_root_path

          expect(response).to be_successful
          expect(response.body).to include("Sign out")

          expect(user.reload.role_codes).to eq([DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE])

          expect(session[:user_id]).to eq(user.id)
        end

        context "and they sign out" do
          it "unsets the session" do
            delete admin_sign_out_path

            expect(session[:user_id]).to be_nil
          end
        end
      end

      context "when the user is a support user" do
        before do
          sign_in_to_admin_with_role(DfeSignIn::User::SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE, dfe_sign_in_id, organisation_id)
        end

        it "renders the admin page, sets a session and applies the appropriate role to the user" do
          get admin_root_path

          expect(response).to be_successful
          expect(response.body).to include("Sign out")

          expect(user.reload.role_codes).to eq([DfeSignIn::User::SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE])

          expect(session[:user_id]).to eq(user.id)
        end
      end

      context "when the user is a payroll operator" do
        before do
          sign_in_to_admin_with_role(DfeSignIn::User::PAYROLL_OPERATOR_DFE_SIGN_IN_ROLE_CODE, dfe_sign_in_id, organisation_id)
        end

        it "renders the page, sets a session and applies the appropriate role to the user" do
          payroll_run = create(:payroll_run)

          get new_admin_payroll_run_download_path(payroll_run)

          expect(response).to be_successful

          expect(user.reload.role_codes).to eq([DfeSignIn::User::PAYROLL_OPERATOR_DFE_SIGN_IN_ROLE_CODE])

          expect(session[:user_id]).to eq(user.id)
        end
      end

      context "when the user is not authorised to access the service" do
        before do
          sign_in_to_admin_with_role("not-the-role-code-we-expect")
        end

        it "shows a not authorised page and doesn’t set a session" do
          expect(session[:user_id]).to be_nil

          expect(response.code).to eq("401")
          expect(response.body).to include("Not authorised")
        end
      end
    end

    context "when the user fails authentication" do
      before do
        OmniAuth.config.mock_auth[:dfe] = :invalid_credentials
      end

      it "shows a not authorised page and doesn’t set a session" do
        post admin_dfe_sign_in_path
        follow_redirect!

        expect(session[:user_id]).to be_nil

        expect(response.body).to redirect_to(
          admin_auth_failure_path(message: :invalid_credentials, strategy: :dfe)
        )
      end
    end

    context "when a local DfeSignIn::User record matching the DfE Sign-in ID does not exist" do
      let(:dfe_sign_in_id) { "userid-345" }
      let(:organisation_id) { "organisationid-6789" }

      it "creates a DfeSignIn::User record and sets the record ID in the session" do
        expect {
          sign_in_to_admin_with_role(DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE, dfe_sign_in_id, organisation_id)
        }.to change {
          DfeSignIn::User.count
        }.by(1)

        user = DfeSignIn::User.last
        expect(user.dfe_sign_in_id).to eq(dfe_sign_in_id)
        expect(user.role_codes).to eq([DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE])

        expect(session[:user_id]).to eq(user.id)
      end
    end
  end
end
