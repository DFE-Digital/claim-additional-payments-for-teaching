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

  describe "service is unavailable" do
    before do
      @original_maintenance_mode_value = Rails.application.config.maintenance_mode
      Rails.application.config.maintenance_mode = maintenance_mode
      Rails.application.reload_routes!
    end

    after do
      Rails.application.config.maintenance_mode = @original_maintenance_mode_value
      Rails.application.reload_routes!
    end

    context "when MAINTENANCE_MODE is set" do
      let(:maintenance_mode) { true }

      it "routes to the maintenance page by default" do
        expect(get: "/").to route_to("static_pages#maintenance")
      end
    end

    context "when MAINTENANCE_MODE is not set" do
      let(:maintenance_mode) { false }

      it "routes to the correct default page" do
        expect(get: "/").to route_to("static_pages#start_page")
      end
    end
  end
end
