require "rails_helper"

RSpec.describe DfeSignIn::AuthenticatedSession do
  let(:user_id) { "12345-user" }
  let(:organisation_id) { "6789-organisation" }
  let(:role_codes) { ["role_code"] }

  describe "initialising with an auth hash" do
    let(:auth_hash) { dfe_sign_in_auth_hash(user_id, organisation_id) }

    subject(:authenticated_session) { DfeSignIn::AuthenticatedSession.from_auth_hash(auth_hash) }

    before do
      stub_dfe_sign_in_user_info_request(user_id, organisation_id, role_codes.first)
    end

    it "sets the user_id" do
      expect(authenticated_session.user_id).to eq user_id
    end

    it "sets the organisation_id" do
      expect(authenticated_session.organisation_id).to eq organisation_id
    end

    it "sets the role_codes" do
      expect(authenticated_session.role_codes).to eq role_codes
    end
  end
end
