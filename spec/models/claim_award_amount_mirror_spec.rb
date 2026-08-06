require "rails_helper"

# award_amount is mid-move from the eligibility tables onto claims. Until the read
# cutover, eligibility remains the source of truth and a before_save on Claim mirrors
# the value onto claims.award_amount, so the cutover is a one-line change.
#
# These cover the paths where the mirror is not obvious: they write the eligibility
# directly and rely on a later `claim.save` to carry the value across. The journey
# submission paths are covered too, because three of the seven policies never touch
# claims.award_amount themselves and depend entirely on the callback.
#
# Delete this file at the read cutover, along with the callback.
#
# Note these assert `claim[:award_amount]`, not `claim.award_amount` — the latter is
# the delegate, so comparing it against the eligibility would pass vacuously.
RSpec.describe "mirroring award_amount onto claims" do
  describe "Admin::AmendmentForm" do
    # The form saves the eligibility and the claim as separate operations, so the
    # mirror depends on `claim.save!` running the callback even when no other claim
    # attribute changed.
    it "mirrors an amended award amount" do
      claim = create(:claim, :submitted, eligibility_attributes: {award_amount: 1000})

      form = Admin::AmendmentForm.new(
        claim: claim,
        admin_user: create(:dfe_signin_user),
        params: {notes: "made some changes", award_amount: 2000}
      )

      expect { form.save }.to change { claim.reload[:award_amount] }.from(1000).to(2000)
      expect(claim[:award_amount]).to eq(claim.eligibility.award_amount)
    end
  end

  describe "ClaimStudentLoanDetailsUpdater" do
    # Writes through nested attributes via Amendment.amend_claim, which never calls
    # Claim#award_amount= at all.
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

      expect(claim[:award_amount]).to eq(claim.eligibility.award_amount)
    end
  end

  describe "journey submission" do
    # FE, TRI and TSLR declare award_amount on their session answers, so the duck-typed
    # build_claim already assigns the column. The other four do not, and rely wholly on
    # the callback — so those are the ones worth asserting.
    [
      Policies::InternationalRelocationPayments,
      Policies::EarlyYearsPayments,
      Policies::EarlyYearsTeachersFinancialIncentivePayments,
      Policies::EarlyCareerPayments
    ].each do |policy|
      it "mirrors on a #{policy} claim built from its eligibility" do
        claim = create(
          :claim,
          :submitted,
          policy: policy,
          eligibility_attributes: {award_amount: 1500}
        )

        expect(claim.reload[:award_amount]).to eq(1500)
        expect(claim[:award_amount]).to eq(claim.eligibility.award_amount)
      end
    end
  end
end
