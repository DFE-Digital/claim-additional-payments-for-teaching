require "rails_helper"

RSpec.describe StudentLoans::SlugSequence do
  subject(:slug_sequence) { StudentLoans::SlugSequence.new(current_claim) }

  let(:claim) { build(:claim) }
  let(:current_claim) { CurrentClaim.new(claims: [claim]) }

  describe "The sequence as defined by #slugs" do
    it "excludes the “ineligible” slug if the claim is not actually ineligible" do
      expect(claim.eligibility).not_to be_ineligible
      expect(slug_sequence.slugs).not_to include("ineligible")

      claim.eligibility.qts_award_year = "before_cut_off_date"
      expect(claim.eligibility).to be_ineligible
      expect(slug_sequence.slugs).to include("ineligible")
    end

    it "excludes “current-school” if the claimant still works at the school they are claiming against" do
      claim.eligibility.employment_status = :claim_school

      expect(slug_sequence.slugs).not_to include("current-school")
    end

    context "when claim payment details are 'personal bank account'" do
      it "excludes the 'building-society-account' slug" do
        claim.bank_or_building_society = :personal_bank_account

        expect(slug_sequence.slugs).not_to include("building-society-account")
      end
    end

    context "when claim payment details are 'building society'" do
      it "excludes the 'personal-bank-account' slug" do
        claim.bank_or_building_society = :building_society

        expect(slug_sequence.slugs).not_to include("personal-bank-account")
      end
    end

    context "when 'provide_mobile_number' is 'No'" do
      it "excludes the 'mobile-number' slug" do
        claim.provide_mobile_number = false

        expect(slug_sequence.slugs).not_to include("mobile-number")
      end

      it "excludes the 'mobile-verification' slug" do
        claim.provide_mobile_number = false

        expect(slug_sequence.slugs).not_to include("mobile-verification")
      end
    end

    context "when 'provide_mobile_number' is 'Yes'" do
      it "includes the 'mobile-number' slug" do
        claim.provide_mobile_number = true

        expect(slug_sequence.slugs).to include("mobile-number")
      end

      it "includes the 'mobile-verification' slug" do
        claim.provide_mobile_number = true

        expect(slug_sequence.slugs).to include("mobile-verification")
      end
    end
  end
end
