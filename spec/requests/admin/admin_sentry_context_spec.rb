require "rails_helper"

RSpec.describe "Admin Sentry context", type: :request do
  describe "when signed in" do
    it "sets the Sentry user context to the signed-in admin's id" do
      user = sign_in_as_service_operator

      expect(Sentry).to receive(:set_user).with(id: user.id).at_least(:once)

      get admin_claims_path
    end
  end

  describe "when not signed in" do
    it "redirects before setting Sentry user context" do
      expect(Sentry).not_to receive(:set_user)

      get admin_claims_path

      expect(response).to redirect_to(admin_sign_in_path)
    end
  end
end
