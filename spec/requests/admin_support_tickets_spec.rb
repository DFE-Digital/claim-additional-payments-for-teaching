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
  end
end
