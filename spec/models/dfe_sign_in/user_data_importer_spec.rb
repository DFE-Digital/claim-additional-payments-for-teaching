require "rails_helper"

RSpec.describe DfeSignIn::UserDataImporter, type: :model do
  before { stub_dfe_sign_in_user_list_request }

  subject do
    DfeSignIn::UserDataImporter.new(user_type: "admin")
  end

  it "imports all user data" do
    subject.run

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
    context "when the user is present in the DfE Sign In API response" do
      context "when the user is not deleted" do
        let!(:existing_user) { create(:dfe_signin_user, dfe_sign_in_id: "5b0e3686-1db7-11ea-978f-2e728ce88125", user_type: "admin") }

        it "updates the user" do
          subject.run

          expect(DfeSignIn::User.count).to eq(3)

          existing_user.reload

          expect(existing_user.given_name).to eq("Alice")
          expect(existing_user.family_name).to eq("Example")
          expect(existing_user.email).to eq("alice@example.com")
          expect(existing_user.organisation_name).to eq("ACME Inc")
        end
      end

      context "when the user was previously deleted" do
        let!(:existing_user) { create(:dfe_signin_user, :deleted, dfe_sign_in_id: "5b0e3686-1db7-11ea-978f-2e728ce88125", user_type: "admin") }

        it "marks the user as not deleted" do
          subject.run
          expect(existing_user.reload.deleted_at).to be_nil
        end
      end
    end

    context "when the user is not present in the DfE Sign In API response" do
      let!(:existing_user) { create(:dfe_signin_user, user_type: "admin") }

      it "deletes the user" do
        subject.run
        expect(existing_user.reload).to be_deleted
      end

      # This scenario happens after first login when using the 'bypass DfE Sign-in' button
      context "when the user does not have a dfe_sign_in_id (dummy user)" do
        let!(:existing_user) { create(:dfe_signin_user, dfe_sign_in_id: nil, user_type: "admin") }

        it "does not delete the user" do
          subject.run
          expect(existing_user.reload).not_to be_deleted
        end
      end
    end
  end
end
