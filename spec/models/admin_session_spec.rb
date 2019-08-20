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

  describe "#is_support_agent?" do
    it "returns true when the session has the right role" do
      admin_session = AdminSession.new("user-id", "organisation-id", [AdminSession::SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE])
      expect(admin_session.is_support_agent?).to eq true

      admin_session = AdminSession.new("user-id", "organisation-id", ["other-role"])
      expect(admin_session.is_support_agent?).to eq false
    end
  end

  describe "#has_admin_access?" do
    it "returns true when user is a service operator" do
      admin_session = AdminSession.new("user-id", "organisation-id", [AdminSession::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE])
      expect(admin_session.has_admin_access?).to eq true
    end

    it "returns true when user is a support user" do
      admin_session = AdminSession.new("user-id", "organisation-id", [AdminSession::SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE])
      expect(admin_session.has_admin_access?).to eq true
    end

    it "returns true when user has both roles" do
      admin_session = AdminSession.new("user-id", "organisation-id", [
        AdminSession::SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE,
        AdminSession::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE,
      ])
      expect(admin_session.has_admin_access?).to eq true
    end

    it "returns false when user does not have a valid role" do
      admin_session = AdminSession.new("user-id", "organisation-id", ["other-role"])
      expect(admin_session.has_admin_access?).to eq false
    end
  end
end
