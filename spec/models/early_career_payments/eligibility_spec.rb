# frozen_string_literal: true

require "rails_helper"

RSpec.describe EarlyCareerPayments::Eligibility, type: :model do
  describe "#policy" do
    let(:early_career_payments_eligibility) { build(:early_career_payments_eligibility) }

    it "has a policy class of 'EarlyCareerPayments'" do
      expect(early_career_payments_eligibility.policy).to eq EarlyCareerPayments
    end
  end

  describe "#ineligible?" do
    it "returns false when the eligiblity cannot be determined" do
      expect(EarlyCareerPayments::Eligibility.new.ineligible?).to eql false
    end

    it "returns true when the NQT acdemic year was not the year after the ITT" do
      expect(EarlyCareerPayments::Eligibility.new(nqt_in_academic_year_after_itt: false).ineligible?).to eql true
      expect(EarlyCareerPayments::Eligibility.new(nqt_in_academic_year_after_itt: true).ineligible?).to eql false
    end
  end

  describe "#award_amount" do
    # TODO we have multiple repayment amounts to consider. Have used the minimum for this spec
    it "returns the £2,000 amount that Early Career Payments claimants are eligible for" do
      expect(EarlyCareerPayments::Eligibility.new.award_amount).to eq(BigDecimal("2000"))
    end
  end

  describe "validation contexts" do
    context "when saving in the 'nqt_in_academic_year_after_itt' context" do
      it "is not valid without a value for 'nqt_in_academic_year_after_itt" do
        expect(EarlyCareerPayments::Eligibility.new).not_to be_valid(:"nqt-in-academic-year-after-itt")
      end
    end
  end
end
