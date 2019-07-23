require "rails_helper"

RSpec.describe "Admin", type: :request do
  describe "admin#index request" do
    let(:organisation_id) { "3bb6e3d7-64a9-42d8-b3f7-cf26101f3e82" }
    let(:stub_url) { "#{DfeSignIn.configuration.base_url}/services/#{DfeSignIn.configuration.client_id}/organisations/#{organisation_id}/users/" }
    let(:stub_response) do
      {
        "roles" => roles,
      }
    end
    let(:roles) { [] }

    before do
      stub_request(:get, stub_url).to_return(status: 200, body: stub_response.to_json)
    end

    context "when the user is not authenticated" do
      it "redirects to the sign in page and doesn’t set a session" do
        get admin_path

        expect(response).to redirect_to(admin_sign_in_path)
        expect(session[:login]).to be_nil
      end
    end

    context "when the user is authenticated" do
      before do
        OmniAuth.config.mock_auth[:dfe] = OmniAuth::AuthHash.new(
          "provider" => "dfe",
          "info" => {"email" => "test-dfe-sign-in@host.tld"},
          "extra" => {
            "raw_info" => {
              "organisation" => {
                "id" => organisation_id,
              },
            },
          }
        )
      end

      context "when the user is authorised to access the service" do
        let(:roles) do
          [
            {
              "id" => "role-id",
              "name" => "My role",
              "code" => Admin::AuthController::DFE_SIGN_IN_ADMIN_ROLE_CODE,
              "numericId" => "9999",
              "status" => {
                "id" => 1,
              },
            },
          ]
        end

        before do
          post admin_dfe_sign_in_path
          follow_redirect!
        end

        it "renders the admin page and sets a session" do
          get admin_path

          expect(response).to be_successful
          expect(response.body).to include("Admin")
          expect(session[:login]).to eql({"email" => "test-dfe-sign-in@host.tld"})
        end

        context "and they sign out" do
          it "unsets the session" do
            delete admin_sign_out_path

            expect(session[:login]).to be_nil
          end
        end
      end

      context "when the user is not authorised to access the service" do
        let(:roles) do
          [
            {
              "id" => "role-id",
              "name" => "My role",
              "code" => "another_role",
              "numericId" => "9999",
              "status" => {
                "id" => 1,
              },
            },
          ]
        end

        before do
          post admin_dfe_sign_in_path
          follow_redirect!
        end

        it "shows a not authorised page and doesn’t set a session" do
          expect(session[:login]).to be_nil
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

        expect(session[:login]).to be_nil
        expect(response.body).to redirect_to(
          admin_auth_failure_path(message: :invalid_credentials, strategy: :dfe)
        )
      end
    end
  end
end
