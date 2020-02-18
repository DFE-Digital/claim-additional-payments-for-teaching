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

      claim.has_student_loan = true
      expect(slug_sequence.slugs).to include("student-loan-country")
      expect(slug_sequence.slugs).to include("student-loan-how-many-courses")
      expect(slug_sequence.slugs).to include("student-loan-start-date")
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

    it "excludes the “gender” slug if the claim's payroll_gender were acquired supplied by GOV.UK Verify" do
      claim.govuk_verify_fields = []
      expect(slug_sequence.slugs).to include("gender")

      claim.govuk_verify_fields = ["payroll_gender"]
      expect(slug_sequence.slugs).to_not include("gender")
    end

    it "excludes the “name” slug if the name has been acquired from GOV.UK Verify" do
      claim.govuk_verify_fields = []
      expect(slug_sequence.slugs).to include("name")

      claim.govuk_verify_fields = ["first_name"]
      expect(slug_sequence.slugs).to_not include("name")
    end

    it "excludes the “address” slug if any address fields were acquired from GOV.UK Verify" do
      claim.govuk_verify_fields = []
      expect(slug_sequence.slugs).to include("address")

      claim.govuk_verify_fields = ["postcode"]
      expect(slug_sequence.slugs).to_not include("address")
    end

    it "excludes the “date-of-birth” slug if the date_of_birth has been acquired from GOV.UK Verify" do
      claim.govuk_verify_fields = []
      expect(slug_sequence.slugs).to include("date-of-birth")

      claim.govuk_verify_fields = ["date_of_birth"]
      expect(slug_sequence.slugs).to_not include("date-of-birth")
    end
  end
end
