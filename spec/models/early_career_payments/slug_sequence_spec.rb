require "rails_helper"

RSpec.describe EarlyCareerPayments::SlugSequence do
  let(:eligibility) { build(:early_career_payments_eligibility) }
  let(:claim) { build(:claim, eligibility: eligibility) }

  subject(:slug_sequence) { EarlyCareerPayments::SlugSequence.new(claim) }

  describe "The sequence as defined by #slugs" do
    it "excludes the “ineligible” slug if the claim is not actually ineligible" do
      expect(claim.eligibility).not_to be_ineligible
      expect(slug_sequence.slugs).not_to include("ineligible")

      claim.eligibility.nqt_in_academic_year_after_itt = false
      expect(claim.eligibility).to be_ineligible
      expect(slug_sequence.slugs).to include("ineligible")
    end

    it "excludes the 'entire-term-contract' slug if the claimant is not a supply teacher" do
      claim.eligibility.employed_as_supply_teacher = false

      expect(slug_sequence.slugs).not_to include("entire-term-contract")
    end

    it "excludes the 'employed-directly' slug if the claimant is not a supply teacher" do
      claim.eligibility.employed_as_supply_teacher = false

      expect(slug_sequence.slugs).not_to include("employed-directly")
    end

    context "when assessing if to include 'eligibility_confirmed' slug" do
      let(:eligibility) { build(:early_career_payments_eligibility, :mathematics_and_itt_year_2018) }

      it "excludes the 'eligibility_confirmed' slug when the claim is ineligible" do
        claim.eligibility.eligible_itt_subject = :modern_foreign_languages

        expect(slug_sequence.slugs).not_to include("eligibility_confirmed")
      end

      it "includes the 'eligibility_confirmed' slug when claim is eligible" do
        expect(slug_sequence.slugs).to include("eligibility_confirmed")
      end
    end
  end
end
