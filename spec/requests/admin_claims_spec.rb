require "rails_helper"

RSpec.describe "Admin claims", type: :request do
  before do
    sign_in_to_admin_with_role(AdminSession::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE)
  end

  describe "claims#index" do
    let!(:claims) { create_list(:claim, 3, :submitted) }
    let!(:checked_claim) { create :claim, :approved }

    it "lists all claims awaiting checking" do
      get admin_claims_path

      claims.each do |c|
        expect(response.body).to include(c.reference)
      end
      expect(response.body).not_to include(checked_claim.reference)
    end

    it "can filter by policy" do
      maths_and_physics_claims = create_list(:claim, 3, :submitted, policy: MathsAndPhysics)
      get admin_claims_path, params: {policy: "maths-and-physics"}

      maths_and_physics_claims.each do |c|
        expect(response.body).to include(c.reference)
      end

      claims.each do |c|
        expect(response.body).to_not include(c.reference)
      end
    end

    it "returns all claims if a policy does not exist" do
      maths_and_physics_claims = create_list(:claim, 3, :submitted, policy: MathsAndPhysics)

      get admin_claims_path, params: {policy: "non-existent-policy"}

      maths_and_physics_claims.each do |c|
        expect(response.body).to include(c.reference)
      end

      claims.each do |c|
        expect(response.body).to include(c.reference)
      end
    end
  end

  describe "claims#show" do
    let(:claim) { create(:claim, :submitted) }

    it "returns the claim" do
      get admin_claim_path(claim)

      expect(response.body).to include(claim.reference)
    end

    context "when another claim has matching attributes" do
      let!(:claim_with_matching_attributes) { create(:claim, :submitted) }

      it "returns the claim and the duplicate" do
        get admin_claim_path(claim)

        expect(response.body).to include(claim.reference)
        expect(response.body).to include(claim_with_matching_attributes.reference)
      end
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
