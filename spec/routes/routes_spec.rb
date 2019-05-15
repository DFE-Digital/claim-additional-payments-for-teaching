require "rails_helper"

describe "Routes", type: :routing do
  describe "Claims routing" do
    it "only routes to pages in the claim sequence" do
      expect(get: "claim/qts-year").to route_to "claims#show", slug: "qts-year"
      expect(get: "claim/claim-school").to route_to "claims#show", slug: "claim-school"

      expect(get: "claim/non-existent-page").not_to be_routable
    end
  end
end
