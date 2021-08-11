require "rails_helper"

RSpec.describe StudentLoans::SlugSequence do
  let(:claim) { build(:claim) }

  subject(:slug_sequence) { StudentLoans::SlugSequence.new(claim) }

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

    it "excludes student loan plan slugs if the claimant is not paying off a student loan" do
      claim.has_student_loan = false
      expect(slug_sequence.slugs).not_to include("student-loan-country")
      expect(slug_sequence.slugs).not_to include("student-loan-how-many-courses")
      expect(slug_sequence.slugs).not_to include("student-loan-start-date")
      expect(slug_sequence.slugs).not_to include("masters-loan")
      expect(slug_sequence.slugs).not_to include("doctoral-loan")

      claim.has_student_loan = true
      expect(slug_sequence.slugs).to include("student-loan-country")
      expect(slug_sequence.slugs).to include("student-loan-how-many-courses")
      expect(slug_sequence.slugs).to include("student-loan-start-date")
      expect(slug_sequence.slugs).to include("masters-loan")
      expect(slug_sequence.slugs).to include("doctoral-loan")
    end

    it "excludes the remaining student loan plan slugs if the claimant received their student loan in a Plan 1 country" do
      claim.has_student_loan = true

      StudentLoan::PLAN_1_COUNTRIES.each do |plan_1_country|
        claim.student_loan_country = plan_1_country
        expect(slug_sequence.slugs).to include("student-loan-country")
        expect(slug_sequence.slugs).not_to include("student-loan-how-many-courses")
        expect(slug_sequence.slugs).not_to include("student-loan-start-date")
      end

      %w[england wales].each do |variable_plan_country|
        claim.student_loan_country = variable_plan_country
        expect(slug_sequence.slugs).to include("student-loan-country")
        expect(slug_sequence.slugs).to include("student-loan-how-many-courses")
        expect(slug_sequence.slugs).to include("student-loan-start-date")
      end
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

    context "when auto-populating address from 'postcode-search' and 'select-home-address'" do
      it "excludes the 'address' slug" do
        claim.postcode = "SE13 7UN"

        expect(slug_sequence.slugs).not_to include("address")
      end
    end

    context "when manual full address requested" do
      it "includes the 'address' slug" do
        claim.postcode = nil

        expect(slug_sequence.slugs).to include("address")
      end
    end
  end
end
