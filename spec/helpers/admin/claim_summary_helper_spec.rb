require "rails_helper"

describe Admin::ClaimsHelper do
  describe "#claim_summary_view" do
    subject { helper.claim_summary_view }

    let(:claim) { build(:claim, policy: policy) }

    before { assign(:claim, claim) }

    Policies.all.excluding(Policies::FurtherEducationPayments).each do |policy|
      context "for policy #{policy}" do
        let(:policy) { policy }

        it { is_expected.to eq "claim_summary" }
      end
    end

    context "for FurtherEducationPayments" do
      let(:policy) { Policies::FurtherEducationPayments }

      it { is_expected.to eq "claim_summary_further_education_payments" }
    end
  end
end