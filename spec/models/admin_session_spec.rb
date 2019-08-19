require "rails_helper"

RSpec.describe AdminSession, type: :model do
  describe "#is_service_operator?" do
    it "returns true when the session has the right role" do
      admin_session = AdminSession.new("user-id", "organisation-id", [AdminSession::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE])
      expect(admin_session.is_service_operator?).to eq true

      admin_session = AdminSession.new("user-id", "organisation-id", ["other-role"])
      expect(admin_session.is_service_operator?).to eq false
    end
  end
end
