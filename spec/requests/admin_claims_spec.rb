require "rails_helper"

RSpec.describe "Admin claims", type: :request do
  before do
    sign_in_to_admin_with_role(AdminSession::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE)
  end

  describe "claims#index" do
    let!(:claims) { create_list(:claim, 3, :submitted) }

    it "lists all claims" do
      get admin_claims_path

      claims.each do |c|
        expect(response.body).to include(c.reference)
      end
    end
  end

  describe "claims#show" do
    let(:claim) { create(:claim, :submitted) }

    it "returns a claim when one exists" do
      get admin_claim_path(claim)

      expect(response.body).to include(claim.reference)
    end
  end

  describe "claims#search" do
    let(:claim) { create(:claim, :submitted) }

    it "redirects to a claim when one exists" do
      get search_admin_claims_path(reference: claim.reference)

      expect(response).to redirect_to(admin_claim_path(claim))
    end

    it "shows an error if a claim can't be found" do
      reference = "12345678"
      get search_admin_claims_path(reference: reference)

      expected_flash = CGI.escapeHTML("Cannot find a claim with reference \"#{reference}\"")
      expect(response.body).to include(expected_flash)
    end
  end
end
