require "rails_helper"

RSpec.describe DfeSignIn::UserHelper, type: :helper do
  describe "#user_details" do
    context "when user has a name assigned" do
      let(:user) { build(:dfe_signin_user, given_name: "Jo", family_name: "Bloggs") }

      it "returns the user's full name" do
        expect(helper.user_details(user)).to eq("Jo Bloggs")
      end
    end

    context "when user has no name assigned" do
      let(:user) { build(:dfe_signin_user, given_name: nil, family_name: nil) }

      it "returns an unknown user message with the user's DfE Sign-In ID" do
        user_details = helper.user_details(user)
        expect(user_details).to match("Unknown user")
        expect(user_details).to match("DfE Sign-in ID - #{user.dfe_sign_in_id}")
      end
    end
  end
end
