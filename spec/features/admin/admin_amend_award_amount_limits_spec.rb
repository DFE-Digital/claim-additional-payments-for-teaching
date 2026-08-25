require "rails_helper"

# CHARACTERISATION SPEC — documents current behaviour, not desired behaviour.
#
# Award amount limits are declared `on: :amendment`, but Admin::AmendmentForm#save
# calls `eligibility.save!` in the *default* context, so those rules never run when
# an award is amended through the admin UI. They only run via Amendment.amend_claim,
# which uses `claim.save(context: :amendment)` and propagates the context through
# autosave (see spec/models/claim_student_loan_details_updater_spec.rb:352).
#
# This is expected to invert when award_amount moves onto Claim: the rules will then
# hang off the record the form itself saves, and these scenarios should start failing.
RSpec.feature "Admin amends an award amount past its limit" do
  before { @signed_in_user = sign_in_as_service_operator }

  def amend_award_to(claim, amount, label: "Award amount")
    visit admin_claim_path(claim)
    click_on "Amend claim"
    fill_in label, with: amount
    fill_in "Change notes", with: "Probing the award amount limit"
    click_on "Amend claim"
  end

  context "with a Student Loans claim" do
    let(:claim) do
      create(
        :claim,
        :submitted,
        award_amount: 550,
        eligibility: build(:student_loans_eligibility, :eligible)
      )
    end

    before { create(:journey_configuration, :student_loans) }

    # The two scenarios below are the decisive pair: same form, same field, two rules.
    # Only the context-gated one is skipped, which is what pins the cause on the
    # validation context rather than on the dispatch being broken.
    scenario "the amendment-only £5,000 limit does not stop the amendment" do
      expect {
        amend_award_to(claim, "5001", label: "Student loan repayment amount")
      }.to change { claim.reload.amendments.size }.by(1)

      expect(claim.eligibility.award_amount).to eq(5_001)
      expect(page).not_to have_content("Enter a positive amount up to £5,000.00")

      # ...while the rule itself considers that value invalid on amendment. Built
      # rather than reloaded because the rule is guarded by `award_amount_changed?`,
      # which is false on a freshly loaded record.
      expect(
        build(:student_loans_eligibility, :eligible, award_amount: 5_001)
      ).not_to be_valid(:amendment)
    end

    # The unconditional rule *does* run here, which is what proves the dispatch is
    # wired up and only the context-gated rule is being skipped. Admin::AmendmentForm
    # does not validate the award amount itself though — it only guards against
    # changing it on policies that disallow it — so the save raises instead of the form
    # re-rendering with an error. That is a 500 for the operator, and is pre-existing:
    # the rule was equally unconditional as `validates_numericality_of` before it was
    # extracted into AwardAmountRules.
    #
    # The message gained an "Eligibility " prefix when claims became the write target:
    # the form now writes claim.award_amount, so the rule fires on the eligibility via
    # the mirror and the claim's autosave, surfacing as a nested error from
    # `claim.save!` rather than directly from `eligibility.save!`.
    scenario "the unconditional £99,999 limit raises rather than showing an error" do
      expect {
        amend_award_to(claim, "100001", label: "Student loan repayment amount")
      }.to raise_error(
        ActiveRecord::RecordInvalid,
        /Eligibility award amount Enter a valid monetary amount/
      )

      expect(claim.reload.amendments).to be_empty
      expect(claim.eligibility.award_amount).to eq(550)
    end
  end

  context "with a Targeted Retention Incentive claim" do
    let(:claim) do
      create(
        :claim,
        :submitted,
        policy: Policies::TargetedRetentionIncentivePayments,
        award_amount: 2_000,
        eligibility: build(:targeted_retention_incentive_payments_eligibility, :eligible)
      )
    end

    before do
      create(:journey_configuration, :targeted_retention_incentive_payments)
      create(:targeted_retention_incentive_payments_award, award_amount: 3_000)
    end

    scenario "the award table maximum does not stop the amendment" do
      expect {
        amend_award_to(claim, "3001")
      }.to change { claim.reload.amendments.size }.by(1)

      expect(claim.eligibility.award_amount).to eq(3_001)

      # TRI has no `award_amount_changed?` guard, so the very record the form just
      # saved is invalid in the amendment context.
      expect(claim.eligibility).not_to be_valid(:amendment)
    end
  end

  context "with a Further Education claim" do
    let(:claim) do
      create(
        :claim,
        :submitted,
        policy: Policies::FurtherEducationPayments,
        award_amount: 2_000,
        eligibility: build(:further_education_payments_eligibility, :eligible)
      )
    end

    before { create(:journey_configuration, :further_education_payments) }

    # Control case: FE lists :award_amount in AMENDABLE_ATTRIBUTES but declares no
    # rule at all, so this passes regardless of validation context. Documents the
    # separate FE gap rather than the context behaviour.
    scenario "any amount is accepted because no rule exists" do
      expect {
        amend_award_to(claim, "99999")
      }.to change { claim.reload.amendments.size }.by(1)

      expect(claim.eligibility.award_amount).to eq(99_999)
    end
  end
end
