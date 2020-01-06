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
      let(:user) { build(:dfe_signin_user, :without_data) }

      it "returns an unknown user message with the user's DfE Sign-In ID" do
        user_details = helper.user_details(user)
        expect(user_details).to eq("Unknown user<br/><span class=\"govuk-!-font-size-16\">(DfE Sign-in ID - #{user.dfe_sign_in_id})</span>")
      end

      it "does not have a line break when include_line_break is set to false" do
        user_details = helper.user_details(user, include_line_break: false)
        expect(user_details).to eq("Unknown user <span class=\"govuk-!-font-size-16\">(DfE Sign-in ID - #{user.dfe_sign_in_id})</span>")
      end
    end
  end
end
