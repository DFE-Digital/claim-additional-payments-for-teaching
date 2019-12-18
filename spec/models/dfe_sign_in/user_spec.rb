require "rails_helper"

RSpec.describe DfeSignIn::User, type: :model do
  let(:user) { build(:dfe_signin_user) }

  describe "full_name" do
    it "returns a full name" do
      expect(user.full_name).to eq("Jo Bloggs")
    end
  end
end
