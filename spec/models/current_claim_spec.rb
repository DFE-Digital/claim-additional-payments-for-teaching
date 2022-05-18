require "rails_helper"

RSpec.describe CurrentClaim, type: :model do
  context "Two claims - ECP and LUP" do
    let(:ecp_policy) { EarlyCareerPayments }
    let(:lup_policy) { LevellingUpPremiumPayments }
    let(:ecp_claim) { build(:claim, academic_year: "2022/2023", policy: ecp_policy) }
    let(:lup_claim) { build(:claim, academic_year: "2022/2023", policy: lup_policy) }
    let(:school) { create(:school) }

    describe "#attributes=" do
      it "sets the attributes on both claims" do
        cc = CurrentClaim.new(claims: [ecp_claim, lup_claim])
        cc.attributes = {"eligibility_attributes" => {"current_school_id" => school.id}}

        expect(cc.claims.first.school.id).to eq(school.id)
        expect(cc.claims.last.school.id).to eq(school.id)
      end
    end

    describe "save!" do
      it "saves both claims" do
        cc = CurrentClaim.new(claims: [ecp_claim, lup_claim])
        cc.attributes = {"eligibility_attributes" => {"current_school_id" => school.id}}

        cc.save!

        expect(ecp_claim.reload.school.id).to eq(school.id)
        expect(lup_claim.reload.school.id).to eq(school.id)
      end
    end
  end
end
