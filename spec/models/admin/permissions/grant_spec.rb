require "rails_helper"

RSpec.describe Admin::Permissions::Grant do
  describe "validations" do
    it "is valid with a known permission" do
      expect(build(:admin_permissions_grant)).to be_valid
    end

    it "is invalid with an unknown permission" do
      grant = build(:admin_permissions_grant, permission: "made_up.permission")

      expect(grant).not_to be_valid
      expect(grant.errors[:permission]).to be_present
    end

    it "is invalid without granted_at" do
      expect(build(:admin_permissions_grant, granted_at: nil)).not_to be_valid
    end

    it "is invalid for a provider user" do
      grant = build(:admin_permissions_grant, user: build(:dfe_signin_user, :provider))

      expect(grant).not_to be_valid
      expect(grant.errors[:user]).to include("must be an admin user")
    end
  end

  describe ".active" do
    it "excludes revoked grants" do
      active = create(:admin_permissions_grant)
      create(:admin_permissions_grant, :revoked)

      expect(described_class.active).to contain_exactly(active)
    end
  end

  describe "database constraints" do
    let(:user) { create(:dfe_signin_user) }

    it "prevents two active grants of the same permission to the same user" do
      create(:admin_permissions_grant, user: user)

      expect {
        build(:admin_permissions_grant, user: user).save!(validate: false)
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "allows re-granting a permission that has been revoked" do
      create(:admin_permissions_grant, :revoked, user: user)

      expect { create(:admin_permissions_grant, user: user) }.not_to raise_error
    end
  end
end
