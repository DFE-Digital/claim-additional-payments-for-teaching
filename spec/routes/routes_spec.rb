require "rails_helper"

RSpec.describe "Routes", type: :routing do
  describe "Claims routing" do
    it "routes GET requests to pages in the policies’ page sequences" do
      expect(get: "student-loans/qts-year").to route_to "claims#show", slug: "qts-year", journey: "student-loans"
    end

    it "routes GET /:policy/claim to the new action" do
      expect(get: "student-loans/claim").to route_to "claims#new", journey: "student-loans"
    end

    it "routes POST /:policy/claim to the create action" do
      expect(post: "student-loans/claim").to route_to "claims#create", journey: "student-loans"
      expect(post: "targeted-retention-incentive-payments/claim").to route_to "claims#create", journey: "targeted-retention-incentive-payments"
    end

    it "routes policy page sequence slugs to the update action" do
      expect(put: "student-loans/claim-school").to route_to "claims#update", slug: "claim-school", journey: "student-loans"
      expect(put: "targeted-retention-incentive-payments/employed-directly").to route_to "claims#update", slug: "employed-directly", journey: "targeted-retention-incentive-payments"
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

  describe "Silence unwanted request and render a 404" do
    context "unwanted extensions" do
      it "returns a 404" do
        %w[axd asp aspx cgi htm html php php7 pl txt xml].each do |extension|
          expect(get: "foo.#{extension}").to route_to(controller: "application", action: "handle_unwanted_requests", path: "foo", format: extension)
        end
      end
    end

    context "folders" do
      it "returns a 404 for .git/config" do
        expect(get: ".git/config").to route_to(controller: "application", action: "handle_unwanted_requests", path: ".git/config")
      end

      it "returns a 404 for cgi-bin" do
        expect(get: "cgi-bin/").to route_to(controller: "application", action: "handle_unwanted_requests", path: "cgi-bin")
      end

      it "returns a 404 for webui" do
        expect(get: "webui/").to route_to(controller: "application", action: "handle_unwanted_requests", path: "webui")
      end
    end

    context "apple icons" do
      it "returns a 404" do
        %w[
          apple-touch-icon
          apple-touch-icon-120x120-precomposed
          apple-touch-icon-120x120
          apple-touch-icon-precomposed
        ].each do |path|
          expect(get: "#{path}.png").to route_to(controller: "application", action: "handle_unwanted_requests", path: path, format: "png")
        end
      end
    end

    context "wordpress" do
      it "returns a 404" do
        %w[
          wordpress
          wp
          wp-admin
          wp-content
          wp-includes
        ].each do |path|
          expect(get: path).to route_to(controller: "application", action: "handle_unwanted_requests", path: path)
        end
      end
    end

    context "misc head requests" do
      before { create(:journey_configuration, :targeted_retention_incentive_payments) }

      let(:some_app_url) do
        Journeys::TargetedRetentionIncentivePayments::SlugSequence.start_page_url
      end

      it "returns a 400" do
        [
          "backup",
          "bc",
          "bk",
          "home",
          "main",
          "new",
          "old",
          some_app_url
        ].each do |path|
          expected_path = path.remove(/\A\//)
          expect(head: path).to route_to(controller: "application", action: "handle_unwanted_requests", path: expected_path)
        end
      end
    end

    context "root requests" do
      it "returns a 404" do
        expect(options: "/").to route_to(controller: "application", action: "handle_unwanted_requests")
      end
    end
  end
end
