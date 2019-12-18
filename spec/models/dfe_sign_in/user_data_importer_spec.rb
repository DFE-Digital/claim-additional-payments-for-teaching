require "rails_helper"

RSpec.describe DfeSignIn::UserDataImporter, type: :model do
  before { stub_dfe_sign_in_user_list_request }

  it "imports all user data" do
    DfeSignIn::UserDataImporter.new.run

    users = DfeSignIn::User.all

    expect(users.count).to eq(3)

    expect(users.first.given_name).to eq("Alice")
    expect(users.first.family_name).to eq("Example")
    expect(users.first.email).to eq("alice@example.com")
    expect(users.first.organisation_name).to eq("ACME Inc")

    expect(users.second.given_name).to eq("Bob")
    expect(users.second.family_name).to eq("Example")
    expect(users.second.email).to eq("bob@example.com")
    expect(users.second.organisation_name).to eq("ACME Inc")

    expect(users.third.given_name).to eq("Eve")
    expect(users.third.family_name).to eq("Example")
    expect(users.third.email).to eq("eve@example.com")
    expect(users.third.organisation_name).to eq("ACME Inc")
  end

  context "when a user already exists" do
    let!(:existing_user) { create(:dfe_signin_user, dfe_sign_in_id: "5b0e3686-1db7-11ea-978f-2e728ce88125") }

    it "updates the user" do
      DfeSignIn::UserDataImporter.new.run

      expect(DfeSignIn::User.count).to eq(3)

      existing_user.reload

      expect(existing_user.given_name).to eq("Alice")
      expect(existing_user.family_name).to eq("Example")
      expect(existing_user.email).to eq("alice@example.com")
      expect(existing_user.organisation_name).to eq("ACME Inc")
    end
  end
end
