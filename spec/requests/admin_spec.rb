require "rails_helper"

RSpec.describe "Admin", type: :request do
  describe "admin#index request" do
    context "when the user is authenticated" do
      before { post sessions_path }

      it "renders the admin page" do
        get admin_path

        expect(response).to be_successful
        expect(response.body).to include("Admin")
      end
    end

    context "when the user is not authenticated" do
      it "redirects to the sign in page" do
        get admin_path

        expect(response).to redirect_to(new_sessions_path)
      end
    end
  end
end
