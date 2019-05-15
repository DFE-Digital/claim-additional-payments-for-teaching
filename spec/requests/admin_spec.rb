require "rails_helper"

RSpec.describe "Admin", type: :request do
  describe "admin#index request" do
    context "when the user is not authenticated" do
      it "redirects to the sign in page and doesn’t set a session" do
        get admin_path

        expect(response).to redirect_to(sign_in_path)
        expect(session[:login]).to be_nil
      end
    end

    context "when the user is authenticated" do
      before do
        get dfe_sign_in_path
        follow_redirect!
      end

      it "renders the admin page and sets a session" do
        get admin_path

        expect(response).to be_successful
        expect(response.body).to include("Admin")
        expect(session[:login]).to eql({"email" => "test@example.com"})
      end

      context "and they sign out" do
        it "unsets the session" do
          delete sign_out_path

          expect(session[:login]).to be_nil
        end
      end
    end
  end
end
