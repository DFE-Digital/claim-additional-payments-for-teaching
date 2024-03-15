require "rails_helper"

RSpec.describe Decision, type: :model do
  let(:user) { create(:dfe_signin_user) }

  describe "associations" do
    it { is_expected.to belong_to(:claim) }
    it { is_expected.to belong_to(:created_by).class_name("DfeSignIn::User").optional(true) }
  end

  it "should not permit changes after creation" do
    claim = create(:claim, :submitted)
    decision = Decision.create!(claim: claim, created_by: user, result: :approved)

    expect { decision.update(created_by: user) }.to raise_error(ActiveRecord::ReadOnlyRecord)

    expect(decision.reload.created_by).to eq(user)
  end

  it "validates the decision has a result" do
    expect(build(:decision, result: "approved", created_by: user)).to be_valid
    expect(build(:decision, result: nil, created_by: user)).not_to be_valid
  end

  it "validates the decision has notes when it's automated" do
    expect(build(:decision, :automated, result: "approved", notes: "Auto-approved")).to be_valid
    expect(build(:decision, :automated, result: "approved", notes: nil)).not_to be_valid
  end

  it "validates that at least one rejected reason is selected when rejecting a claim" do
    decision = build(:decision, :rejected, rejected_reasons: {})

    expect(decision).not_to be_valid
    expect(decision.errors.messages[:rejected_reasons]).to eq(["At least one reason is required"])
  end

  it "validates that the selected rejected reasons are valid when rejecting a claim" do
    claim = create(:claim, :submitted, policy: Policies::EarlyCareerPayments)
    decision = build(:decision, :rejected, claim: claim, rejected_reasons: {invalid: "1"})

    expect(decision).not_to be_valid
    expect(decision.errors.messages[:rejected_reasons]).to eq(["One or more reasons are not selectable for this claim"])
  end

  it "prevents an unapprovable claim from being approved" do
    claim = create(:claim, :ineligible)
    decision = build(:decision, claim: claim, result: "approved")

    expect(decision).not_to be_valid
    expect(decision.errors.messages[:base]).to eq(["This claim cannot be approved"])
  end

  it "prevents an unrejectable claim from being rejected" do
    claim = create(:claim, :held)
    decision = build(:decision, claim: claim, result: "rejected")

    expect(decision).not_to be_valid
    expect(decision.errors.messages[:base]).to eq(["This claim cannot be rejected"])
  end

  it "prevents a decision being marked as undone when a claim cannot have its decision undone" do
    claim = create(:claim, :submitted)
    decision = create(:decision, claim: claim, result: "approved")
    create(:payment, claims: [claim])
    decision.undone = true
    decision.save

    expect(decision).not_to be_valid
    expect(decision.errors.messages[:base]).to eq(["This claim cannot have its decision undone"])
  end

  it "prevents a claim with matching bank details from being approved" do
    personal_details = {
      teacher_reference_number: generate(:teacher_reference_number),
      bank_sort_code: "112233"
    }

    create(:claim, :approved, personal_details.merge(bank_account_number: "12345678"))
    claim_to_approve = create(:claim, :submitted, personal_details.merge(bank_account_number: "99999999"))
    decision = build(:decision, claim: claim_to_approve, result: "approved")

    expect(decision).not_to be_valid
    expect(decision.errors.messages[:base]).to eq(["This claim cannot be approved"])
  end

  context "`rejected_reasons` store accessor" do
    let(:decision) { build_stubbed(:decision) }
    let(:prefix) { "rejected_reasons" }

    described_class::REJECTED_REASONS.each do |reason|
      let(:reader) { "#{prefix}_#{reason}" }
      let(:setter) { "#{prefix}_#{reason}=" }

      it "can set and read the value of `#{reason}`" do
        expect { decision.public_send(setter, "1") }.to change { decision.public_send(reader) }.to("1")
      end
    end
  end

  describe ".rejected_reasons_for" do
    subject { described_class.rejected_reasons_for(policy) }

    let(:expected_reasons_ecp) do
      [
        :ineligible_subject,
        :ineligible_year,
        :ineligible_school,
        :ineligible_qualification,
        :induction,
        :no_qts_or_qtls,
        :duplicate,
        :no_response,
        :other
      ]
    end
    let(:expected_reasons_non_ecp) do
      [
        :ineligible_subject,
        :ineligible_year,
        :ineligible_school,
        :ineligible_qualification,
        :no_qts_or_qtls,
        :duplicate,
        :no_response,
        :other
      ]
    end

    context "when the claim policy is ECP" do
      let(:policy) { Policies::EarlyCareerPayments }

      it { is_expected.to eq(expected_reasons_ecp) }
    end

    context "when the claim policy is LUP" do
      let(:policy) { Policies::LevellingUpPremiumPayments }

      it { is_expected.to eq(expected_reasons_non_ecp) }
    end

    context "when the claim policy is TSLR" do
      let(:policy) { Policies::StudentLoans }

      it { is_expected.to eq(expected_reasons_non_ecp) }
    end
  end

  describe "#rejected_reasons_hash" do
    subject { decision.rejected_reasons_hash }

    let(:decision) { create(:decision, :rejected, **rejected_reasons) }
    let(:rejected_reasons) do
      {
        rejected_reasons_ineligible_subject: "1",
        rejected_reasons_no_qts_or_qtls: "1"
      }
    end
    let(:expected_hash) do
      {
        reason_ineligible_subject: "1",
        reason_ineligible_year: "0",
        reason_ineligible_school: "0",
        reason_ineligible_qualification: "0",
        reason_no_qts_or_qtls: "1",
        reason_duplicate: "0",
        reason_induction: "0",
        reason_no_response: "0",
        reason_other: "0"
      }
    end

    it "returns the complete hash of rejected reasons" do
      is_expected.to eq(expected_hash)
    end
  end

  describe "#selected_rejected_reasons" do
    subject { decision.selected_rejected_reasons }

    let(:decision) { create(:decision, :rejected, **rejected_reasons) }
    let(:rejected_reasons) do
      {
        rejected_reasons_ineligible_subject: "1",
        rejected_reasons_no_qts_or_qtls: "1"
      }
    end

    it "returns the rejected reasons that have been selected" do
      is_expected.to eq([:ineligible_subject, :no_qts_or_qtls])
    end
  end
end
