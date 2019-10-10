require "rails_helper"

RSpec.describe "Admin", type: :request do
  describe "admin#index request" do
    context "when the user is not authenticated" do
      it "redirects to the sign in page and doesn’t set a session" do
        get admin_root_path

        expect(response).to redirect_to(admin_sign_in_path)
        expect(session[:user_id]).to be_nil
        expect(session[:organisation_id]).to be_nil
        expect(session[:role_codes]).to be_nil
      end
    end

    context "when the user is authenticated" do
      let(:user_id) { "userid-345" }
      let(:organisation_id) { "organisationid-6789" }

      context "when the user is a service operator" do
        before do
          sign_in_to_admin_with_role(AdminSession::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE, user_id, organisation_id)
        end

        it "renders the admin page and sets a session" do
          get admin_root_path

          expect(response).to be_successful
          expect(response.body).to include("Sign out")
          expect(session[:user_id]).to eq(user_id)
          expect(session[:organisation_id]).to eq(organisation_id)
          expect(session[:role_codes]).to eq([AdminSession::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE])
        end

        context "and they sign out" do
          it "unsets the session" do
            delete admin_sign_out_path

            expect(session[:user_id]).to be_nil
            expect(session[:organisation_id]).to be_nil
            expect(session[:role_codes]).to be_nil
          end
        end
      end

      context "when the user is a support user" do
        before do
          sign_in_to_admin_with_role(AdminSession::SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE, user_id, organisation_id)
        end

        it "renders the admin page and sets a session" do
          get admin_root_path

          expect(response).to be_successful
          expect(response.body).to include("Sign out")
          expect(session[:user_id]).to eq(user_id)
          expect(session[:organisation_id]).to eq(organisation_id)
          expect(session[:role_codes]).to eq([AdminSession::SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE])
        end
      end

      context "when the user is not authorised to access the service" do
        before do
          sign_in_to_admin_with_role("not-the-role-code-we-expect")
        end

        it "shows a not authorised page and doesn’t set a session" do
          expect(session[:user_id]).to be_nil
          expect(session[:organisation_id]).to be_nil
          expect(session[:role_codes]).to be_nil

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
        expect(session[:organisation_id]).to be_nil
        expect(session[:role_codes]).to be_nil

        expect(response.body).to redirect_to(
          admin_auth_failure_path(message: :invalid_credentials, strategy: :dfe)
        )
      end
    end
  end
end
