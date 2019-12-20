require "rails_helper"

RSpec.describe DfeSignIn::User, type: :model do
  let(:user) { build(:dfe_signin_user) }

  describe "full_name" do
    it "returns a full name" do
      expect(user.full_name).to eq("Jo Bloggs")
    end
  end

  describe "#is_service_operator?" do
    it "returns true when the user has the right role" do
      user.role_codes = [DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE]
      expect(user.is_service_operator?).to eq true

      user.role_codes = ["other-role"]
      expect(user.is_service_operator?).to eq false
    end
  end

  describe "#is_support_agent?" do
    it "returns true when the user has the right role" do
      user.role_codes = [DfeSignIn::User::SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE]
      expect(user.is_support_agent?).to eq true

      user.role_codes = ["other-role"]
      expect(user.is_support_agent?).to eq false
    end
  end

  describe "#has_admin_access?" do
    it "returns true when user is a service operator" do
      user.role_codes = [DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE]
      expect(user.has_admin_access?).to eq true
    end

    it "returns true when user is a support user" do
      user.role_codes = [DfeSignIn::User::SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE]
      expect(user.has_admin_access?).to eq true
    end

    it "returns true when user is a payroll operator" do
      user.role_codes = [DfeSignIn::User::PAYROLL_OPERATOR_DFE_SIGN_IN_ROLE_CODE]
      expect(user.has_admin_access?).to eq true
    end

    it "returns true when user has multiple roles" do
      user.role_codes = [
        DfeSignIn::User::SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE,
        DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE,
      ]

      expect(user.has_admin_access?).to eq true
    end

    it "returns false when user does not have a valid role" do
      user.role_codes = ["other-role"]

      expect(user.has_admin_access?).to eq false
    end
  end
end
