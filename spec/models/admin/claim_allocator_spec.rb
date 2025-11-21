require "rails_helper"

RSpec.describe Admin::ClaimAllocator do
  let(:ecp_claim) { create(:claim, :submitted, policy: Policies::EarlyCareerPayments) }
  let(:tslr_claim) { create(:claim, :submitted, policy: Policies::StudentLoans) }
  let(:maxime) { create(:dfe_signin_user, given_name: "Maxime", family_name: "Toussaint", organisation_name: "Department for Education", role_codes: [DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE]) }
  let(:sofia) { create(:dfe_signin_user, given_name: "Sofia", family_name: "Bianchi", organisation_name: "Department for Education", role_codes: [DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE]) }

  it "assigns a claim team member to a claim" do
    expect(ecp_claim.assigned_to_id).to be_nil

    described_class.new(claim_ids: ecp_claim.id, admin_user_id: sofia.id).call

    expect(ecp_claim.reload.assigned_to).not_to be_nil
    expect(ecp_claim.assigned_to.full_name).to eq "Sofia Bianchi"
  end

  it "a claim team member can be assign mutiple claims" do
    expect(ecp_claim.assigned_to_id).to be_nil
    expect(tslr_claim.assigned_to_id).to be_nil

    described_class.new(claim_ids: [ecp_claim.id, tslr_claim.id], admin_user_id: maxime.id).call

    expect(ecp_claim.reload.assigned_to).not_to be_nil
    expect(tslr_claim.reload.assigned_to).not_to be_nil
    expect(ecp_claim.assigned_to.full_name).to eq "Maxime Toussaint"
    expect(tslr_claim.assigned_to.full_name).to eq "Maxime Toussaint"
  end
end
