require "rails_helper"

RSpec.describe "admin/my_claims/show.html.erb" do
  context "FE claim" do
    let(:admin) do
      create(
        :dfe_signin_user,
        :service_operator
      )
    end

    let!(:ey_claim_without_submitted_at) do
      create(
        :claim,
        :submitted,
        submitted_at: nil,
        policy: Policies::EarlyYearsPayments,
        assigned_to: admin
      )
    end

    it "does not throw an error" do
      assign(:my_claims, Admin::MyClaims.new(current_admin: admin))

      render
    end
  end
end
