require "rails_helper"

RSpec.describe "layouts/application.html.erb" do
  before do
    allow(ENV).to receive(:[]).with("GOOGLE_ANALYTICS_ID").and_return("foo")
    allow(ENV).to receive(:[]).with("GTM_ANALYTICS").and_return("foo")

    without_partial_double_verification do
      allow(view).to receive(:current_journey_routing_name).and_return("further-education-payments")
      allow(view).to receive(:journey).and_return(Journeys::FurtherEducationPayments)
      allow(view).to receive(:journey_service_name).and_return("some-service")
    end
  end

  context "when cookies not accepted" do
    it "does not render tracking scripts" do
      without_partial_double_verification do
        allow(view).to receive(:cookies_accepted?).and_return(false)
      end

      render

      expect(rendered).not_to match("google")
    end
  end

  context "when cookies accepted" do
    it "renders tracking scripts" do
      without_partial_double_verification do
        allow(view).to receive(:cookies_accepted?).and_return(true)
      end

      render

      expect(rendered).to match("google")
    end
  end
end
