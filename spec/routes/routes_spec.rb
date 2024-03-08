require "rails_helper"

describe "Routes", type: :routing do
  describe "Claims routing" do
    it "routes GET requests to pages in the policies’ page sequences" do
      expect(get: "student-loans/qts-year").to route_to "claims#show", slug: "qts-year", journey: "student-loans"
    end

    it "routes GET /:policy/claim to the new action" do
      expect(get: "student-loans/claim").to route_to "claims#new", journey: "student-loans"
    end

    it "routes POST /:policy/claim to the create action" do
      expect(post: "student-loans/claim").to route_to "claims#create", journey: "student-loans"
      expect(post: "additional-payments/claim").to route_to "claims#create", journey: "additional-payments"
    end

    it "routes policy page sequence slugs to the update action" do
      expect(put: "student-loans/claim-school").to route_to "claims#update", slug: "claim-school", journey: "student-loans"
      expect(put: "additional-payments/employed-directly").to route_to "claims#update", slug: "employed-directly", journey: "additional-payments"
    end

    it "does not route for unrecognised policies" do
      expect(get: "non-existent-policy/qts-year").not_to be_routable
      expect(put: "non-existent-policy/qts-year").not_to be_routable
      expect(post: "non-existent-policy/qts-year").not_to be_routable
    end

    it "does not route to pages not in a policy’s page sequences" do
      expect(get: "student-loans/teaching-maths-or-physics").not_to be_routable
    end

    it "allows positionable routing parameters in the URL helpers" do
      expect(claim_path("student-loans", "claim-school")).to eq "/student-loans/claim-school"
    end
  end

  describe "Admin claim tasks routing" do
    it "routes GET requests to valid tasks on a claim" do
      claim = create(:claim, :submitted)
      expect(get: "admin/claims/#{claim.id}/tasks/qualifications").to route_to "admin/tasks#show", claim_id: claim.id, name: "qualifications"
      expect(get: "admin/claims/#{claim.id}/tasks/employment").to route_to "admin/tasks#show", claim_id: claim.id, name: "employment"
    end

    it "does not route for unrecognised tasks" do
      claim = create(:claim, :submitted)
      expect(get: "admin/claims/#{claim.id}/tasks/foo").not_to be_routable
    end
  end
end
