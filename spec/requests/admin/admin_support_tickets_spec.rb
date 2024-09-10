require "rails_helper"

RSpec.describe "admin/support_tickets controller" do
  let(:claim) { create(:claim, :submitted) }

  describe "admin/support_tickets#create" do
    before { @signed_in_user = sign_in_as_service_operator }

    it "creates a SupportTicket against the Claim when the user is a service operator" do
      post admin_claim_support_tickets_path(claim), params: {support_ticket: {url: "https://some/ticket/url"}}

      expect(response).to redirect_to(admin_claim_notes_path(claim))

      expect(claim.support_ticket).to be_present
      expect(claim.support_ticket.url).to eq("https://some/ticket/url")
      expect(claim.support_ticket.created_by).to eq(@signed_in_user)
    end

    it "shows an error message when the URL is not valid" do
      post admin_claim_support_tickets_path(claim), params: {support_ticket: {url: "not/a/real/ticket/url"}}

      expect(claim.support_ticket).not_to be_present
      expect(response.body).to include("Enter a valid support ticket URL")
    end

    it "refuses requests from users without the service operator role" do
      non_service_operator_roles.each do |role|
        sign_in_to_admin_with_role(role)

        post admin_claim_support_tickets_path(claim), params: {support_ticket: {url: "https://some/ticket/url"}}

        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to include("Not authorised")
      end
    end
  end
end
