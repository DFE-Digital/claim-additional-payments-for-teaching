require "rails_helper"

describe "Routes", type: :routing do
  describe "Claims routing" do
    it "only routes to valid policies" do
      expect(get: "student-loans/qts-year").to be_routable
      expect(get: "non-existent-policy/qts-year").not_to be_routable
    end

    it "only routes to pages in the claim sequence" do
      expect(get: "student-loans/qts-year").to route_to "claims#show", slug: "qts-year", policy: "student-loans"
      expect(get: "student-loans/claim-school").to route_to "claims#show", slug: "claim-school", policy: "student-loans"

      expect(get: "student-loans/non-existent-page").not_to be_routable
    end
  end
end
