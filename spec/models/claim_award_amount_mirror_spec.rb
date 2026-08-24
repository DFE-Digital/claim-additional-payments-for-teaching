require "rails_helper"

# award_amount has moved from the eligibility tables onto claims. A before_validation on
# Claim mirrors the value back down so the eligibility copy stays current for the
# validations still declared there, and so the move stays reversible.
#
# These cover every path that writes an award amount, asserting both columns agree
# afterwards. That is the load-bearing guarantee of this stage: a writer that only set
# one side would leave the other stale, and nothing else would notice.
#
# Delete this file when the mirror and the eligibility validations go.
RSpec.describe "mirroring award_amount onto the eligibility" do
  describe "Admin::AmendmentForm" do
    it "mirrors an amended award amount down to the eligibility" do
      claim = create(:claim, :submitted, eligibility_attributes: {award_amount: 1000})

      form = Admin::AmendmentForm.new(
        claim: claim,
        admin_user: create(:dfe_signin_user),
        params: {notes: "made some changes", award_amount: 2000}
      )

      expect { form.save }.to change { claim.reload[:award_amount] }.from(1000).to(2000)
      expect(claim.eligibility.reload.award_amount).to eq(2000)
    end
  end

  describe "ClaimStudentLoanDetailsUpdater" do
    it "mirrors an award amount amended from SLC data" do
      claim = create(
        :claim,
        :submitted,
        policy: Policies::StudentLoans,
        has_student_loan: nil,
        student_loan_plan: nil,
        eligibility_attributes: {award_amount: 0}
      )
      claim.reload

      create(
        :student_loans_data,
        nino: claim.national_insurance_number,
        date_of_birth: claim.date_of_birth,
        plan_type_of_deduction: 1,
        amount: 50
      )

      expect {
        ClaimStudentLoanDetailsUpdater
          .new(claim, create(:dfe_signin_user))
          .update_claim_with_latest_data
      }.to change { claim.reload[:award_amount] }.from(0).to(50)

      expect(claim.eligibility.reload.award_amount).to eq(50)
    end
  end

  describe "saving a claim" do
    # FE, TRI and TSLR assign the column from their session answers via the duck typed
    # build_claim; IRP, EYP and EYTFI assign it explicitly. Either way the mirror is
    # what keeps the eligibility in step.
    [
      Policies::InternationalRelocationPayments,
      Policies::EarlyYearsPayments,
      Policies::EarlyYearsTeachersFinancialIncentivePayments,
      Policies::EarlyCareerPayments
    ].each do |policy|
      it "mirrors down on a #{policy} claim" do
        claim = create(:claim, :submitted, policy: policy)
        claim.update!(award_amount: 1500)

        expect(claim.reload[:award_amount]).to eq(1500)
        expect(claim.eligibility.reload.award_amount).to eq(1500)
      end
    end

    it "mirrors a nil award amount" do
      claim = create(:claim, :submitted, eligibility_attributes: {award_amount: 1000})

      claim.update!(award_amount: nil)

      expect(claim.eligibility.reload.award_amount).to be_nil
    end

    it "does not mirror when the eligibility has no award_amount column" do
      claim = build(:claim)
      allow(claim.eligibility).to receive(:has_attribute?).with(:award_amount).and_return(false)

      expect { claim.save! }.not_to raise_error
    end
  end
end
