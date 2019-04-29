require "rails_helper"

describe "Routes", type: :routing do
  describe "Claims routing" do
    it "only routes to pages in the claim sequence" do
      expect(get: "claims/qts_year").to route_to "claims#show", slug: "qts_year"
      expect(get: "claims/claim_school").to route_to "claims#show", slug: "claim_school"

      expect(get: "claims/non_existent_page").not_to be_routable
    end
  end
end
