require "rails_helper"

describe "Routes", type: :routing do
  describe "Claims routing" do
    it "routes GET requests to pages in the policies’ page sequences" do
      expect(get: "student-loans/qts-year").to route_to "claims#show", slug: "qts-year", policy: "student-loans"
    end

    it "routes /:policy/claim to the create action" do
      expect(post: "student-loans/claim").to route_to "claims#create", policy: "student-loans"
    end

    it "routes policy page sequence slugs to the update action" do
      expect(put: "student-loans/claim-school").to route_to "claims#update", slug: "claim-school", policy: "student-loans"
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
end
