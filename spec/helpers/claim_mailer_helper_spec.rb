require "rails_helper"

RSpec.describe ClaimMailerHelper do
  describe ".rejected_reasons_personalisation" do
    subject { rejected_reasons_personalisation(decision.rejected_reasons_hash) }
    let(:claim) { create(:claim, policy: Policies::EarlyCareerPayments) }
    let(:decision) { create(:decision, :rejected, :with_notes, claim: claim, **rejected_reasons) }

    context "with rejected reasons that don't include 'other'" do
      let(:rejected_reasons) do
        {
          rejected_reasons_ineligible_subject: "1",
          rejected_reasons_ineligible_school: "1"
        }
      end
      let(:expected_personalisation) do
        {
          reason_ineligible_subject: "yes",
          reason_ineligible_year: "no",
          reason_ineligible_school: "yes",
          reason_ineligible_qualification: "no",
          reason_induction: "no",
          reason_no_qts_or_qtls: "no",
          reason_duplicate: "no",
          reason_no_response: "no",
          reason_other: "no"
        }
      end

      it "returns 'yes'/'no' for each reason based on their binary value" do
        is_expected.to eq(expected_personalisation)
      end
    end

    context "with rejected reasons that include 'other'" do
      let(:rejected_reasons) do
        {
          rejected_reasons_ineligible_subject: "1",
          rejected_reasons_ineligible_school: "1",
          rejected_reasons_other: "1"
        }
      end
      let(:expected_personalisation) do
        {
          reason_ineligible_subject: "no",
          reason_ineligible_year: "no",
          reason_ineligible_school: "no",
          reason_ineligible_qualification: "no",
          reason_induction: "no",
          reason_no_qts_or_qtls: "no",
          reason_duplicate: "no",
          reason_no_response: "no",
          reason_other: "yes"
        }
      end

      it "returns 'yes' for 'other' reasons only" do
        is_expected.to eq(expected_personalisation)
      end
    end
  end
end
