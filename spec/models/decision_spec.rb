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
      national_insurance_number: "QQ123456C",
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
    let(:expected_reasons_tslr) do
      [
        :ineligible_subject,
        :ineligible_year,
        :ineligible_school,
        :ineligible_qualification,
        :no_qts_or_qtls,
        :no_repayments_to_slc,
        :duplicate,
        :no_response,
        :other
      ]
    end
    let(:expected_reasons_ey) do
      [
        :claim_cancelled_by_employer,
        :identity_check_failed,
        :six_month_retention_check_failed,
        :duplicate,
        :no_response,
        :other
      ]
    end

    context "when the claim policy is ECP" do
      let(:policy) { Policies::EarlyCareerPayments }

      it { is_expected.to eq(expected_reasons_ecp) }
    end

    context "when the claim policy is Targeted Retention Incentive" do
      let(:policy) { Policies::TargetedRetentionIncentivePayments }

      it { is_expected.to eq(expected_reasons_non_ecp) }
    end

    context "when the claim policy is TSLR" do
      let(:policy) { Policies::StudentLoans }

      it { is_expected.to eq(expected_reasons_tslr) }
    end

    context "when the claim policy is EY" do
      let(:policy) { Policies::EarlyYearsPayments }

      it { is_expected.to eql(expected_reasons_ey) }
    end
  end

  describe "#rejected_reasons_hash" do
    subject { decision.rejected_reasons_hash }

    let(:decision) { create(:decision, :rejected, claim: claim, **rejected_reasons) }

    context "with an ECP claim" do
      let(:claim) { create(:claim, policy: Policies::EarlyCareerPayments) }

      let(:rejected_reasons) do
        {
          rejected_reasons_ineligible_subject: "1",
          rejected_reasons_no_qts_or_qtls: "1"
        }
      end

      it do
        is_expected.to eq(
          reason_ineligible_subject: "1",
          reason_ineligible_year: "0",
          reason_ineligible_school: "0",
          reason_ineligible_qualification: "0",
          reason_no_qts_or_qtls: "1",
          reason_duplicate: "0",
          reason_induction: "0",
          reason_no_response: "0",
          reason_other: "0"
        )
      end
    end

    context "with an Targeted Retention Incentive claim" do
      let(:claim) { create(:claim, policy: Policies::TargetedRetentionIncentivePayments) }

      let(:rejected_reasons) do
        {
          rejected_reasons_ineligible_subject: "1",
          rejected_reasons_no_qts_or_qtls: "1"
        }
      end

      it do
        is_expected.to eq(
          reason_ineligible_subject: "1",
          reason_ineligible_year: "0",
          reason_ineligible_school: "0",
          reason_ineligible_qualification: "0",
          reason_no_qts_or_qtls: "1",
          reason_duplicate: "0",
          reason_no_response: "0",
          reason_other: "0"
        )
      end
    end

    context "with a TSLR claim" do
      let(:rejected_reasons) do
        {
          rejected_reasons_ineligible_subject: "1",
          rejected_reasons_no_qts_or_qtls: "1"
        }
      end

      let(:claim) { create(:claim, policy: Policies::StudentLoans) }

      it do
        is_expected.to eq(
          reason_ineligible_subject: "1",
          reason_ineligible_year: "0",
          reason_ineligible_school: "0",
          reason_ineligible_qualification: "0",
          reason_no_qts_or_qtls: "1",
          reason_no_repayments_to_slc: "0",
          reason_duplicate: "0",
          reason_no_response: "0",
          reason_other: "0"
        )
      end
    end

    context "with an EY claim" do
      let(:rejected_reasons) do
        {
          rejected_reasons_claim_cancelled_by_employer: "1",
          rejected_reasons_six_month_retention_check_failed: "1"
        }
      end

      let(:claim) { create(:claim, policy: Policies::EarlyYearsPayments) }

      it do
        is_expected.to eq(
          reason_claim_cancelled_by_employer: "1",
          reason_identity_check_failed: "0",
          reason_six_month_retention_check_failed: "1",
          reason_duplicate: "0",
          reason_no_response: "0",
          reason_other: "0"
        )
      end
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

  # FIXME RL: Remove these tests once we've removed the enum
  describe "#apporved" do
    subject { decision.read_attribute(:approved) }

    context "when result is approved" do
      context "when set by a string" do
        let(:decision) { create(:decision, result: "approved") }

        it { is_expected.to be(true) }
      end

      context "when set by a symbol" do
        let(:decision) { create(:decision, result: :approved) }

        it { is_expected.to be(true) }
      end

      context "when set by a number" do
        let(:decision) { create(:decision, result: 0) }

        it { is_expected.to be(true) }
      end

      context "when set by scope" do
        let(:decision) do
          Decision.approved.create!(
            claim: create(:claim, :approveable),
            notes: "test"
          )
        end

        it { is_expected.to be(true) }
      end

      context "when set by a method" do
        let(:decision) { build(:decision, :with_notes).tap(&:approved!) }

        it { is_expected.to be(true) }
      end
    end

    context "when result is rejected" do
      subject { decision.read_attribute(:approved) }

      context "when result is approved" do
        context "when set by a string" do
          let(:decision) do
            create(
              :decision,
              result: "rejected",
              rejected_reasons: {"ineligible_subject" => "1"}
            )
          end

          it { is_expected.to be(false) }
        end

        context "when set by a symbol" do
          let(:decision) do
            create(
              :decision,
              result: :rejected,
              rejected_reasons: {"ineligible_subject" => "1"}
            )
          end

          it { is_expected.to be(false) }
        end

        context "when set by a number" do
          let(:decision) do
            create(
              :decision,
              result: 1,
              rejected_reasons: {"ineligible_subject" => "1"}
            )
          end

          it { is_expected.to be(false) }
        end

        context "when set by scope" do
          let(:decision) do
            Decision.rejected.create!(
              claim: create(:claim),
              notes: "test",
              rejected_reasons: {"ineligible_subject" => "1"}
            )
          end

          it { is_expected.to be(false) }
        end

        context "when set by a method" do
          let(:decision) do
            build(
              :decision,
              :with_notes,
              rejected_reasons: {"ineligible_subject" => "1"}
            ).tap(&:rejected!)
          end

          it { is_expected.to be(false) }
        end
      end
    end
  end
end
