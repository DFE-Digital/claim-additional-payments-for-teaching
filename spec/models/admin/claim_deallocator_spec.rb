require "rails_helper"

RSpec.describe Admin::ClaimDeallocator do
  let(:ecp_claim_1) { create(:claim, :submitted, policy: Policies::EarlyCareerPayments) }
  let(:ecp_claim_2) { create(:claim, :submitted, policy: Policies::EarlyCareerPayments) }
  let(:tslr_claim) { create(:claim, :submitted, policy: Policies::StudentLoans) }
  let(:anhe) { create(:dfe_signin_user, given_name: "Anhe", family_name: "Huang-Zhang", organisation_name: "Department for Education", role_codes: [DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE]) }
  let(:betje) { create(:dfe_signin_user, given_name: "Betje", family_name: "Van de Berg", organisation_name: "Department for Education", role_codes: [DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE]) }
  let(:lana) { create(:dfe_signin_user, given_name: "Lana", family_name: "Abbotsworth", organisation_name: "Department for Education", role_codes: [DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE]) }

  it "unassigns a claim team member from a claim" do
    ecp_claim_1.update_attribute(:assigned_to_id, anhe.id)
    expect(ecp_claim_1.assigned_to.full_name).to eq "Anhe Huang-Zhang"
    expect(ecp_claim_1.assigned_to.family_name).not_to eq "Betje Van de Berg"

    described_class.new(claim_ids: ecp_claim_1.id, admin_user_id: anhe.id).call

    expect(ecp_claim_1.reload.assigned_to).to be_nil
  end

  it "a claim team member can be unassign mutiple claims" do
    ecp_claim_1.update_attribute(:assigned_to_id, anhe.id)
    ecp_claim_2.update_attribute(:assigned_to_id, lana.id)
    tslr_claim.update_attribute(:assigned_to_id, anhe.id)

    expect(ecp_claim_1.assigned_to.full_name).to eq "Anhe Huang-Zhang"
    expect(tslr_claim.assigned_to.full_name).to eq "Anhe Huang-Zhang"
    expect(ecp_claim_2.assigned_to.full_name).to eq "Lana Abbotsworth"

    described_class.new(claim_ids: [ecp_claim_1.id, tslr_claim.id], admin_user_id: anhe.id).call

    expect(tslr_claim.reload.assigned_to).to be_nil
    expect(ecp_claim_1.reload.assigned_to).to be_nil
    expect(ecp_claim_2.reload.assigned_to.full_name).to eq "Lana Abbotsworth"
  end
end
