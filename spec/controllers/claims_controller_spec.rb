require "rails_helper"

RSpec.describe ClaimsController do
  describe "#admin_component_preview_enabled_for_current_journey?" do
    it "returns false in production even when a preview session exists" do
      controller = described_class.new
      session = {
        admin_component_preview: {
          journey: Journeys::TeacherStudentLoanReimbursement.routing_name,
          expires_at: 1.hour.from_now.to_i
        }
      }

      allow(Rails.env).to receive(:production?).and_return(true)
      allow(controller).to receive(:session).and_return(session)
      allow(controller).to receive(:current_journey_routing_name).and_return(Journeys::TeacherStudentLoanReimbursement.routing_name)

      expect(controller.send(:admin_component_preview_enabled_for_current_journey?)).to be(false)
    end
  end
end
