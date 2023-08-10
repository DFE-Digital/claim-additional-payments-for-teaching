require "rails_helper"

RSpec.describe "Admin static pages", type: :request do
  describe "GET /admin/accessibility-statement" do
    context "when unauthenticated" do
      it "redirects to the sign in page" do
        get admin_accessibility_statement_path

        expect(response).to redirect_to(admin_sign_in_path)
      end
    end

    context "when authenticated" do
      let!(:sign_in) { sign_in_as_service_operator }

      it "renders the expected page", :aggregate_failures do
        get admin_accessibility_statement_path

        expect(response).to be_successful
        expect(response.body)
          .to include("Accessibility statement for Claim additional payments for teaching Administration site")
      end
    end
  end
end
