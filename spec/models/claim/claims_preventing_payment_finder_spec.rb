require "rails_helper"

RSpec.describe Claim::ClaimsPreventingPaymentFinder do
  let(:user) { create(:dfe_signin_user) }
  let!(:journey_configuration) { create(:journey_configuration, :additional_payments) }
  subject(:finder) { described_class.new(claim) }

  describe "#claims_preventing_payment" do
    let(:personal_details) do
      {
        bank_account_number: "32828838",
        bank_sort_code: "183828",
        first_name: "Boris",
        national_insurance_number: "QQ123456C",
        eligibility_attributes: {teacher_reference_number: generate(:teacher_reference_number)}
      }
    end
    let(:claim) { create(:claim, :submitted, personal_details) }
    subject(:claims_preventing_payment) { finder.claims_preventing_payment }

    context "when there is another claim with the same teacher reference number, with inconsistent personal details that would prevent us from running payroll" do
      let(:inconsistent_personal_details) do
        personal_details.merge(
          bank_account_number: "87282828",
          bank_sort_code: "388183"
        )
      end

      it "does not include the other claim when the other claim is not yet approved" do
        create(:claim, :submitted, inconsistent_personal_details)
        expect(claims_preventing_payment).to be_empty
      end

      it "includes the other claim when the other claim is approved but not yet payrolled" do
        other_claim = create(:claim, :approved, inconsistent_personal_details)
        expect(claims_preventing_payment).to eq([other_claim])
      end

      it "does not include the other claim when the other claim is already payrolled" do
        other_claim = create(:claim, :approved, inconsistent_personal_details)
        create(:payment, claims: [other_claim])
        expect(claims_preventing_payment).to be_empty
      end

      it "includes the other claim where a topup is payrollable" do
        lup_eligibility = create(
          :levelling_up_premium_payments_eligibility,
          :eligible,
          award_amount: 1500.0
        )

        other_claim = create(
          :claim,
          :approved,
          inconsistent_personal_details.merge(
            policy: Policies::LevellingUpPremiumPayments,
            eligibility: lup_eligibility
          )
        )
        create(:payment, claims: [other_claim])
        other_claim.topups.create(award_amount: "500.00", created_by: user)

        expect(claims_preventing_payment).to eq([other_claim])
      end
    end

    context "when there is another claim with the same teacher reference number, with inconsistent details that would not prevent us from running payroll" do
      let(:inconsistent_personal_details) do
        personal_details.merge(
          first_name: "Jarvis"
        )
      end

      it "does not include the other claim even if that claim is approved and not yet payrolled" do
        create(:claim, :approved, inconsistent_personal_details)
        expect(claims_preventing_payment).to be_empty
      end
    end

    context "when there is another claim with a blank value" do
      let(:blank_personal_details) do
        personal_details.merge(
          building_society_roll_number: ""
        )
      end

      it "does not include the other claim" do
        create(:claim, :approved, blank_personal_details)
        expect(claims_preventing_payment).to be_empty
      end
    end
  end
end
