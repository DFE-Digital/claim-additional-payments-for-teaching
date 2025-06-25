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

    it "does not match deleted users" do
      create(:dfe_signin_user, :deleted, dfe_sign_in_id: session.user_id, role_codes: [])
      expect(user).to be_nil
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

    it "returns true when user is a service admin" do
      user.role_codes = [DfeSignIn::User::SERVICE_ADMIN_DFE_SIGN_IN_ROLE_CODE]
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
    let!(:davide) { create(:dfe_signin_user, :service_operator, given_name: "Davide", family_name: "Muzani") }
    let!(:tina) { create(:dfe_signin_user, :service_operator, given_name: "Tina", family_name: "Dee") }
    let!(:muhammad) { create(:dfe_signin_user, :service_operator, given_name: "Muhammad", family_name: "Khan") }
    let!(:deleted_user) { create(:dfe_signin_user, :service_operator, :deleted) }

    it "returns an array of 'Service Operators' for use with select helper" do
      expect(described_class.options_for_select).to match_array(
        [
          [davide.full_name.titleize, davide.id],
          [tina.full_name.titleize, tina.id],
          [muhammad.full_name.titleize, muhammad.id]
        ]
      )
    end

    it "does not include deleted users" do
      expect(described_class.options_for_select).not_to include([deleted_user.full_name.titleize, deleted_user.id])
    end
  end

  describe ".not_deleted" do
    let!(:not_deleted_user) { create(:dfe_signin_user) }

    before { create(:dfe_signin_user, :deleted) }

    it "returns only users without deleted timestamp" do
      expect(described_class.not_deleted.to_a).to eq [not_deleted_user]
    end
  end

  describe "#mark_as_deleted!" do
    context "when the user is not already deleted" do
      let(:user) { create(:dfe_signin_user) }

      it "sets the user 'deleted_at' timestamp to the current time" do
        freeze_time do
          expect { user.mark_as_deleted! }.to change { user.deleted_at }.from(nil).to(Time.zone.now)
        end
      end

      context "when the user has claims assigned" do
        let!(:claim) { create(:claim, :submitted, assigned_to: user) }

        it "unassigns their claims" do
          user.mark_as_deleted!
          expect(claim.reload.assigned_to).to be_nil
        end
      end
    end

    context "when the user is already deleted" do
      let(:user) { create(:dfe_signin_user, :deleted) }

      it "does not change the flag if was already enabled" do
        expect { user.mark_as_deleted! }.not_to change(user, :deleted_at)
      end
    end
  end

  describe "#deleted?" do
    context "when the user is deleted" do
      subject(:user) { create(:dfe_signin_user, :deleted) }

      it { is_expected.to be_deleted }
    end

    context "when the user is not already deleted" do
      subject(:user) { create(:dfe_signin_user) }

      it { is_expected.not_to be_deleted }
    end
  end

  describe "Slack notifications" do
    context "in the production environment" do
      before do
        allow(ENV).to receive(:fetch).with("ENVIRONMENT_NAME").and_return("production")
      end

      context "when the user has admin access" do
        it "sends a notification on record creation" do
          expect { described_class.create!(role_codes: [described_class::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE]) }.to have_enqueued_job(DfeSignIn::SlackNotificationJob)
        end
      end

      context "when the user does not have admin access" do
        it "sends a notification on record creation" do
          expect { described_class.create!(role_codes: []) }.not_to have_enqueued_job(DfeSignIn::SlackNotificationJob)
        end
      end
    end

    context "in any non-production environment" do
      ["local", "test", "review"].each do |environment_name|
        before do
          allow(ENV).to receive(:fetch).with("ENVIRONMENT_NAME").and_return(environment_name)
        end

        it "does not send a notification on record creation" do
          expect { described_class.create!(role_codes: [described_class::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE]) }.not_to have_enqueued_job(DfeSignIn::SlackNotificationJob)
        end
      end
    end
  end
end
