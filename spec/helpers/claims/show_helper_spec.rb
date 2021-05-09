require "rails_helper"

RSpec.describe Claims::ShowHelper do
  let(:claim) { build(:claim, policy: policy) }

  describe "#claim_submitted_title(claim)" do
    context "with a StudentLoans policy" do
      let(:policy) { StudentLoans }

      it "returns the correct content block" do
        expect(helper.claim_submitted_title(claim)).to include("Claim submitted")
      end
    end

    context "with a EarlyCareerPayments policy" do
      let(:policy) { EarlyCareerPayments }

      it "returns the correct content block" do
        expect(helper.claim_submitted_title(claim)).to include("Application complete")
      end
    end
  end

  describe "#shared_view_css_class_size(claim)" do
    context "with a StudentLoans policy" do
      let(:policy) { StudentLoans }

      it "returns the correct css sizing" do
        expect(helper.shared_view_css_class_size(claim)).to eq "xl"
      end
    end

    context "with a EarlyCareerPayments policy" do
      let(:policy) { EarlyCareerPayments }

      it "returns the correct css sizing" do
        expect(helper.shared_view_css_class_size(claim)).to eq "l"
      end
    end
  end
end
