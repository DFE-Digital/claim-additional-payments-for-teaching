require "rails_helper"

RSpec.describe DfeSignIn::User, type: :model do
  let(:user) { build(:dfe_signin_user) }

  describe ".from_session" do
    let(:session) { DfeSignIn::AuthenticatedSession.new(123, 456, ["some-role"]) }
    let(:user) { DfeSignIn::User.from_session(session) }

    it "initializes a user when the user does not exist" do
      user = DfeSignIn::User.from_session(session)

      expect(user.id).to be_nil
      expect(user.dfe_sign_in_id).to eq("123")
      expect(user.role_codes).to eq(["some-role"])
    end

    it "returns an existing user and updates their role codes" do
      existing_user = create(:dfe_signin_user, dfe_sign_in_id: session.user_id, role_codes: [])

      expect(user.id).to eq(existing_user.id)
      expect(user.dfe_sign_in_id).to eq("123")
      expect(user.role_codes).to eq(["some-role"])
    end
  end

  describe "#full_name" do
    it "returns a full name" do
      expect(user.full_name).to eq("Aaron Admin")
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
        DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE
      ]

      expect(user.has_admin_access?).to eq true
    end

    it "returns false when user does not have a valid role" do
      user.role_codes = ["other-role"]

      expect(user.has_admin_access?).to eq false
    end
  end

  describe ".options_for_select" do
    let!(:davide) { create(:dfe_signin_user, given_name: "Davide", family_name: "Muzani", organisation_name: "Department for Education", role_codes: [DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE]) }
    let!(:tina) { create(:dfe_signin_user, given_name: "Tina", family_name: "Dee", organisation_name: "Department for Education", role_codes: [DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE]) }
    let!(:muhammad) { create(:dfe_signin_user, given_name: "Muhammad", family_name: "Khan", organisation_name: "Department for Education", role_codes: [DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE]) }
    let!(:tripti) { create(:dfe_signin_user, given_name: "Tripti", family_name: "Kumar", organisation_name: "Cantium Business Services", role_codes: [DfeSignIn::User::PAYROLL_OPERATOR_DFE_SIGN_IN_ROLE_CODE]) }

    it "returns an array of 'Service Operators' for use with select helper" do
      expect(described_class.options_for_select).to match_array(
        [
          [davide.full_name.titleize, davide.id],
          [tina.full_name.titleize, tina.id],
          [muhammad.full_name.titleize, muhammad.id]
        ]
      )
    end

    it "does not include 'Payroll Operator' role" do
      expect(described_class.options_for_select).not_to include([tripti.full_name.titleize, tripti.id])
    end
  end

  describe ".options_for_select_by_name" do
    let!(:florence) { create(:dfe_signin_user, given_name: "Florence", family_name: "Mani", organisation_name: "Department for Education", role_codes: [DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE]) }
    let!(:rudi) { create(:dfe_signin_user, given_name: "Rudi", family_name: "Gogen-Swift", organisation_name: "Department for Education", role_codes: [DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE]) }
    let!(:henrietta) { create(:dfe_signin_user, given_name: "henrietta", family_name: "krafstein", organisation_name: "Department for Education", role_codes: [DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE]) }
    let!(:miguel) { create(:dfe_signin_user, given_name: "Miguel", family_name: "Hernández", organisation_name: "Cantium Business Services", role_codes: [DfeSignIn::User::PAYROLL_OPERATOR_DFE_SIGN_IN_ROLE_CODE]) }

    it "returns an array of 'Service Operators' for use with select helper" do
      expect(described_class.options_for_select_by_name).to match_array(
        [
          [florence.full_name.titleize, "Florence-Mani"],
          [rudi.full_name.titleize, "Rudi-Gogen-Swift"],
          [henrietta.full_name.titleize, "henrietta-krafstein"]
        ]
      )
    end

    it "does not include 'Payroll Operator' role" do
      expect(described_class.options_for_select_by_name).not_to include([miguel.full_name.titleize, "miguel-hernández"])
    end
  end
end
