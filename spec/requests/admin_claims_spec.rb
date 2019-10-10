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
end
